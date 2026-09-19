const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { checkRateLimit } = require("./rateLimit");
const { FUNCTIONS_REGION } = require("./shared/region");

function normalizeRating(value) {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return null;
  const rounded = Math.round(n);
  if (rounded < 1 || rounded > 5) return null;
  return rounded;
}

function isDelivered(order) {
  return (
    order.status === "delivered" ||
    order.deliveryPhase === "delivered" ||
    order.deliveryDeliveredAt != null
  );
}

function assertRatingRequest(order, uid) {
  if (order.customerId !== uid) {
    throw new HttpsError("permission-denied", "لا يمكنك تقييم هذا الطلب.");
  }
  if (!isDelivered(order)) {
    throw new HttpsError("failed-precondition", "الطلب لم يُسلّم بعد.");
  }
  if (order.driverRating != null) {
    throw new HttpsError("already-exists", "تم تقييم هذا الطلب مسبقاً.");
  }
  const deliveryId = order.deliveryId;
  if (!deliveryId || typeof deliveryId !== "string") {
    throw new HttpsError("failed-precondition", "لا يوجد مندوب لهذا الطلب.");
  }
  return deliveryId;
}

/**
 * تقييم المندوب — يحدّث الطلب ومتوسط تقييم المندوب بشكل آمن.
 *
 * Note: لا ترمِ HttpsError داخل runTransaction — Firebase يحوّلها إلى INTERNAL.
 */
const submitDriverRating = onCall({ region: FUNCTIONS_REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  await checkRateLimit(db, `driverRating:${uid}`, 30, 60 * 1000);

  const orderId =
    typeof request.data?.orderId === "string" ? request.data.orderId.trim() : "";
  const rating = normalizeRating(request.data?.rating);

  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId مطلوب.");
  }
  if (rating == null) {
    throw new HttpsError("invalid-argument", "التقييم يجب أن يكون بين 1 و 5.");
  }

  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    throw new HttpsError("not-found", "الطلب غير موجود.");
  }

  const order = orderSnap.data();
  const deliveryId = assertRatingRequest(order, uid);

  try {
    const driverRef = db.collection("users").doc(deliveryId);

    await db.runTransaction(async (tx) => {
      const freshSnap = await tx.get(orderRef);
      const driverSnap = await tx.get(driverRef);

      if (!freshSnap.exists) {
        throw new Error("ORDER_NOT_FOUND");
      }

      const fresh = freshSnap.data();
      if (fresh.driverRating != null) {
        throw new Error("ALREADY_RATED");
      }

      tx.update(orderRef, {
        driverRating: rating,
        driverRatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      if (driverSnap.exists) {
        const d = driverSnap.data();
        const prevCount =
          typeof d.driverRatingCount === "number" ? d.driverRatingCount : 0;
        const prevAvg =
          typeof d.avgDriverRating === "number" ? d.avgDriverRating : 0;
        const nextCount = prevCount + 1;
        const nextAvg = (prevAvg * prevCount + rating) / nextCount;
        tx.update(driverRef, {
          driverRatingCount: nextCount,
          avgDriverRating: Math.round(nextAvg * 10) / 10,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error?.message === "ALREADY_RATED") {
      throw new HttpsError("already-exists", "تم تقييم هذا الطلب مسبقاً.");
    }
    if (error?.message === "ORDER_NOT_FOUND") {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }
    logger.error("submitDriverRating transaction failed", {
      orderId,
      uid,
      error: error?.message || String(error),
    });
    throw new HttpsError("internal", "تعذّر حفظ التقييم — حاول مرة أخرى.");
  }

  return { ok: true, orderId, rating };
});

module.exports = { submitDriverRating, normalizeRating, isDelivered, assertRatingRequest };
