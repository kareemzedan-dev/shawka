const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  assertCanManageOrders,
  resolveRole,
} = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");
const { isAssignmentEligible } = require("./eligibility");
const {
  enqueueAssignRoundJob,
  clearActiveOrderLock,
  generateOperationId,
} = require("./offerManager");
const { runAssignOrderRound } = require("./assignOrderRoundCore");
const { isReadyForDriverAssignment } = require("../shared/orderStatusFlow");

const ELIGIBILITY_AR = {
  cash_blocked: "المندوب محظور نقدياً",
  presence: "المندوب غير متصل (Offline)",
  gps_trust: "GPS المندوب موقوف/مقيد",
  active_order_lock: "المندوب لديه طلب نشط حالياً",
  offer_cooldown: "المندوب في فترة تهدئة بعد رفض عرض",
  no_location: "لا يوجد موقع GPS للمندوب",
};

const adminReassignDelivery = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    assertCanManageOrders(auth.token);

    const db = getFirestore();
    await checkRateLimit(db, `adminReassign:${auth.uid}`, 30, 60 * 1000);

    const orderId =
      typeof request.data?.orderId === "string" ? request.data.orderId.trim() : "";
    const mode =
      typeof request.data?.mode === "string" ? request.data.mode : "auto";
    const driverId =
      typeof request.data?.driverId === "string"
        ? request.data.driverId.trim()
        : "";
    const reason =
      typeof request.data?.reason === "string"
        ? request.data.reason.slice(0, 300)
        : "admin_reassign";
    // التجاوز اليدوي من الأدمن = فرض تعيين طوارئ
    const force = mode === "manual" || request.data?.force === true;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId مطلوب.");
    }
    if (mode !== "auto" && mode !== "manual") {
      throw new HttpsError("invalid-argument", "mode يجب auto أو manual.");
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }
    const order = orderSnap.data();

    if (order.status === "delivered" || order.status === "cancelled") {
      throw new HttpsError(
        "failed-precondition",
        "لا يمكن التخصيص لطلب مسلّم أو ملغي.",
      );
    }

    if (mode === "auto" && !isReadyForDriverAssignment(order.status)) {
      throw new HttpsError(
        "failed-precondition",
        "غيّر حالة الطلب إلى «جاهز للاستلام» أولاً.",
      );
    }

    if (
      mode === "manual" &&
      !order.deliveryId &&
      !order.offeredDriverId &&
      !isReadyForDriverAssignment(order.status)
    ) {
      throw new HttpsError(
        "failed-precondition",
        "غيّر حالة الطلب إلى «جاهز للاستلام» أولاً.",
      );
    }

    const prevDriver = order.deliveryId || order.offeredDriverId;

    if (prevDriver) {
      await clearActiveOrderLock(db, {
        driverId: prevDriver,
        orderId,
        actorUid: auth.uid,
        reason: "admin_reassign",
      });
    }

    if (mode === "manual") {
      if (!driverId) {
        throw new HttpsError("invalid-argument", "driverId مطلوب للوضع manual.");
      }

      const driverSnap = await db.collection("users").doc(driverId).get();
      if (!driverSnap.exists || resolveRole(driverSnap.data()) !== "delivery") {
        throw new HttpsError("failed-precondition", "المندوب غير موجود.");
      }

      const driverData = driverSnap.data();
      if (driverData.isActive === false) {
        throw new HttpsError(
          "failed-precondition",
          "حساب المندوب غير نشط — فعّله من قسم التوصيل.",
        );
      }

      if (!force) {
        const eligibility = isAssignmentEligible(
          driverData,
          Date.now(),
          undefined,
          {
            governorate: order.governorate,
            storeLat: order.storeLat,
            storeLng: order.storeLng,
          },
        );
        if (!eligibility.eligible) {
          const ar =
            ELIGIBILITY_AR[eligibility.reason] || eligibility.reason || "غير مؤهل";
          throw new HttpsError(
            "failed-precondition",
            `المندوب غير مؤهل للتخصيص: ${ar}`,
          );
        }
      }

      const driverName = driverData.name || "مندوب";
      const driverPhone =
        typeof driverData.phone === "string" ? driverData.phone.trim() : "";
      const driverVehicleType = driverData.vehicleType || "motorcycle";
      const driverRef = db.collection("users").doc(driverId);

      await db.runTransaction(async (tx) => {
        const [freshOrder, freshDriver] = await Promise.all([
          tx.get(orderRef),
          tx.get(driverRef),
        ]);
        if (!freshOrder.exists || !freshDriver.exists) {
          throw new HttpsError("not-found", "الطلب أو المندوب غير موجود.");
        }
        const d = freshDriver.data();
        if (
          typeof d.activeOrderId === "string" &&
          d.activeOrderId.length > 0 &&
          d.activeOrderId !== orderId
        ) {
          throw new HttpsError(
            "failed-precondition",
            `المندوب مشغول بطلب آخر (${d.activeOrderId.slice(0, 8)}…).`,
          );
        }

        tx.update(orderRef, {
          deliveryId: driverId,
          deliveryName: driverName,
          deliveryPhone: driverPhone,
          deliveryVehicleType: driverVehicleType,
          status: "onTheWay",
          deliveryPhase: "accepted",
          assignmentStatus: "accepted",
          offeredDriverId: FieldValue.delete(),
          deliveryAcceptDeadline: FieldValue.delete(),
          offeredAt: FieldValue.delete(),
          deliveryAssignedAt: FieldValue.serverTimestamp(),
          deliveryAcceptedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        tx.update(driverRef, {
          activeOrderId: orderId,
          isDriverOnline: true,
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      await writeAuditLog(db, {
        type: "admin_reassign_delivery",
        actorUid: auth.uid,
        actorRole: auth.token.staffRole || "admin",
        targetType: "order",
        targetId: orderId,
        details: { mode, driverId, reason, force: true },
      });

      return {
        ok: true,
        mode,
        orderId,
        driverId,
        driverName,
        event: "admin_reassign_delivery",
        message: `تم تعيين ${driverName} للطلب بنجاح`,
      };
    }

    // ── Auto assignment engine ──────────────────────────────────────
    await orderRef.update({
      deliveryId: FieldValue.delete(),
      deliveryName: FieldValue.delete(),
      deliveryPhone: FieldValue.delete(),
      deliveryVehicleType: FieldValue.delete(),
      offeredDriverId: FieldValue.delete(),
      deliveryPhase: "unassigned",
      assignmentStatus: "searching",
      assignmentRound: 1,
      rejectedDriverIds: [],
      deliveryRejectReason: FieldValue.delete(),
      candidateDriverIds: FieldValue.delete(),
      assignmentOperationId: FieldValue.delete(),
      deliveryAcceptDeadline: FieldValue.delete(),
      offeredAt: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const operationId = generateOperationId();
    await enqueueAssignRoundJob(db, orderId, 1, operationId);

    let roundResult = null;
    let roundError = null;
    try {
      roundResult = await runAssignOrderRound(db, {
        orderId,
        round: 1,
        operationId,
      });
    } catch (err) {
      roundError = err;
    }

    const fresh = (await orderRef.get()).data() || {};
    const offeredDriverId =
      typeof fresh.offeredDriverId === "string" ? fresh.offeredDriverId : "";
    const assignmentStatus = fresh.assignmentStatus || "searching";

    await writeAuditLog(db, {
      type: "admin_reassign_delivery",
      actorUid: auth.uid,
      actorRole: auth.token.staffRole || "admin",
      targetType: "order",
      targetId: orderId,
      details: {
        mode,
        reason,
        prevDriver,
        offeredDriverId: offeredDriverId || null,
        assignmentStatus,
        roundError: roundError ? String(roundError.message || roundError) : null,
      },
    });

    if (offeredDriverId) {
      return {
        ok: true,
        mode,
        orderId,
        offeredDriverId,
        assignmentStatus,
        event: "admin_reassign_delivery",
        message: "تم إرسال عرض الطلب للمندوب الأقرب — راقب تطبيق الدليفري.",
      };
    }

    if (assignmentStatus === "failed") {
      throw new HttpsError(
        "failed-precondition",
        "لا يوجد مندوبون متاحون الآن (يجب أن يكون المندوب متصل وجاهز). تأكد أن تطبيق الدليفري Online ثم أعد المحاولة أو استخدم التجاوز اليدوي.",
      );
    }

    // Still searching / queued for next round
    return {
      ok: true,
      mode,
      orderId,
      assignmentStatus,
      event: "admin_reassign_delivery",
      message:
        "بدأ محرك التخصيص البحث. إن لم يظهر العرض خلال دقيقة: فعّل Online للمندوب أو استخدم التجاوز اليدوي.",
      queued: true,
      roundResult: roundResult || null,
    };
  },
);

module.exports = { adminReassignDelivery };
