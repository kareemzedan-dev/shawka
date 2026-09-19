const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  canManageOrders,
  isCustomerOwner,
} = require("../shared/permissions");
const { clearActiveOrderLock } = require("./offerManager");

async function executeCancelOrder(db, { orderId, uid, token, reason = "cancelled" }) {
  const orderRef = db.collection("orders").doc(orderId);
  let driverToRelease = null;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }
    const order = snap.data();

    const isStaff = canManageOrders(token);
    if (!isStaff && !isCustomerOwner(order, uid)) {
      throw new HttpsError("permission-denied", "PERMISSION_DENIED");
    }

    if (order.status === "delivered") {
      throw new HttpsError("failed-precondition", "ALREADY_DELIVERED");
    }

    driverToRelease = order.deliveryId || order.offeredDriverId || null;

    tx.update(orderRef, {
      status: "cancelled",
      deliveryPhase: "cancelled",
      assignmentStatus: "cancelled",
      offeredDriverId: FieldValue.delete(),
      deliveryAcceptDeadline: FieldValue.delete(),
      offeredAt: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
      cancelReason: reason,
      cancelledBy: uid,
      cancelledAt: FieldValue.serverTimestamp(),
    });
  });

  if (driverToRelease) {
    try {
      await clearActiveOrderLock(db, {
        driverId: driverToRelease,
        orderId,
        actorUid: uid,
        reason: "order_cancelled",
      });
    } catch (e) {
      if (!String(e.message || e).includes("ORDER_LOCK_MISMATCH")) {
        throw e;
      }
    }
  }

  return { ok: true, event: "order_cancelled", orderId };
}

const cancelOrder = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const db = getFirestore();
    const uid = auth.uid;

    await checkRateLimit(db, `cancelOrder:${uid}`, 20, 60 * 1000);

    const orderId =
      typeof request.data?.orderId === "string" ? request.data.orderId : "";
    const reason =
      typeof request.data?.reason === "string"
        ? request.data.reason.slice(0, 200)
        : "cancelled";

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId مطلوب.");
    }

    return executeCancelOrder(db, {
      orderId,
      uid,
      token: auth.token,
      reason,
    });
  },
);

module.exports = { cancelOrder, executeCancelOrder };
