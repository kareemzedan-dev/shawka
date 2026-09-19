const { HttpsError } = require("firebase-functions/v2/https");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getConfig } = require("../shared/config");
const {
  hasActiveOrderLock,
  isDriverApproved,
  isCashBlockedUser,
  TERMINAL_PHASES,
} = require("./eligibility");
const { writeAuditLog } = require("../shared/audit");
const { applyOfferAcceptedTx } = require("../shared/driverOfferStats");
const { resetRejectStreakTx, applyRejectCooldownTx } = require("../shared/driverCooldown");
const { refreshDriverScore } = require("../driver/driverPerformanceScore");

function generateOperationId() {
  return `op_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}

function isDeadlinePassed(deadline, nowMs = Date.now()) {
  if (!deadline) return true;
  const ms =
    typeof deadline.toMillis === "function"
      ? deadline.toMillis()
      : deadline instanceof Date
        ? deadline.getTime()
        : typeof deadline === "number"
          ? deadline
          : null;
  return ms == null || ms <= nowMs;
}

/**
 * Pure pre-check for accept — used by acceptOffer and tests.
 * Do NOT re-run full assignment eligibility (no_location / presence):
 * the driver already received this offer; blocking accept after that
 * leaves the Delv app stuck on a spinner / failed accept.
 */
function checkAcceptEligibility(order, driver, driverId, nowMs = Date.now()) {
  if (order.deliveryId && order.deliveryId !== driverId) {
    return "ALREADY_ASSIGNED";
  }
  if (order.offeredDriverId !== driverId) {
    return "NOT_OFFERED_DRIVER";
  }
  if (order.deliveryPhase !== "offered") {
    return "NOT_OFFERED_DRIVER";
  }
  if (isDeadlinePassed(order.deliveryAcceptDeadline, nowMs)) {
    return "DEADLINE_EXCEEDED";
  }
  if (hasActiveOrderLock(driver)) {
    return "ACTIVE_ORDER_LOCK";
  }
  if (isCashBlockedUser(driver)) {
    return "INELIGIBLE:cash_blocked";
  }
  if (!isDriverApproved(driver) || driver.isActive === false) {
    return "INELIGIBLE:not_approved";
  }
  return null;
}

async function driverHasActiveDeliveryQuery(db, driverId) {
  const snap = await db
    .collection("orders")
    .where("deliveryId", "==", driverId)
    .limit(5)
    .get();

  for (const doc of snap.docs) {
    const phase = doc.data().deliveryPhase;
    if (!phase || !TERMINAL_PHASES.has(phase)) {
      return doc.id;
    }
    const status = doc.data().status;
    if (status && status !== "delivered" && status !== "cancelled") {
      return doc.id;
    }
  }
  return null;
}

/**
 * Accept offer atomically — §11.2.
 */
async function acceptOffer(db, { orderId, driverId, operationId, config }) {
  const cfg = config || getConfig();
  const orderRef = db.collection("orders").doc(orderId);
  const driverRef = db.collection("users").doc(driverId);

  return db.runTransaction(async (tx) => {
    const [orderSnap, driverSnap] = await Promise.all([
      tx.get(orderRef),
      tx.get(driverRef),
    ]);

    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }
    const order = orderSnap.data();

    if (order.assignmentOperationId === operationId && order.deliveryId === driverId) {
      return { ok: true, duplicate: true, orderId };
    }

    if (order.deliveryId && order.deliveryId !== driverId) {
      throw new HttpsError("failed-precondition", "ALREADY_ASSIGNED");
    }

    if (order.offeredDriverId !== driverId) {
      throw new HttpsError("failed-precondition", "NOT_OFFERED_DRIVER");
    }

    if (order.deliveryPhase !== "offered") {
      throw new HttpsError("failed-precondition", "NOT_OFFERED_DRIVER");
    }

    if (isDeadlinePassed(order.deliveryAcceptDeadline)) {
      throw new HttpsError("deadline-exceeded", "DEADLINE_EXCEEDED");
    }

    if (!driverSnap.exists) {
      throw new HttpsError("not-found", "المندوب غير موجود.");
    }
    const driver = driverSnap.data();

    const blockReason = checkAcceptEligibility(order, driver, driverId);
    if (blockReason === "ACTIVE_ORDER_LOCK") {
      throw new HttpsError("failed-precondition", "ACTIVE_ORDER_LOCK");
    }
    if (blockReason) {
      throw new HttpsError("failed-precondition", blockReason);
    }

    const driverName = driver.name || "مندوب";
    const driverPhone =
      typeof driver.phone === "string" ? driver.phone.trim() : "";
    const driverVehicleType = driver.vehicleType || "motorcycle";

    tx.update(orderRef, {
      deliveryId: driverId,
      deliveryName: driverName,
      deliveryPhone: driverPhone,
      deliveryVehicleType: driverVehicleType,
      // Match admin force-assign so customer/admin + Delv active views agree.
      status: "onTheWay",
      deliveryPhase: "accepted",
      assignmentStatus: "accepted",
      offeredDriverId: FieldValue.delete(),
      deliveryAcceptedAt: FieldValue.serverTimestamp(),
      assignmentOperationId: operationId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(driverRef, {
      activeOrderId: orderId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    applyOfferAcceptedTx(tx, driverRef, driver);
    resetRejectStreakTx(tx, driverRef);

    return { ok: true, orderId, driverId, driverName };
  }).then(async (result) => {
    if (result.ok && !result.duplicate) {
      try {
        await refreshDriverScore(db, driverId);
      } catch (_) {
        /* non-blocking */
      }
    }
    return result;
  });
}

/**
 * Reject offer — add to rejectedDriverIds, clear offer fields, enqueue next round.
 */
async function rejectOffer(db, { orderId, driverId, reason, config }) {
  const cfg = config || getConfig();
  const orderRef = db.collection("orders").doc(orderId);

  const result = await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }
    const order = orderSnap.data();

    if (order.offeredDriverId !== driverId) {
      throw new HttpsError("failed-precondition", "NOT_OFFERED_DRIVER");
    }

    const rejected = Array.isArray(order.rejectedDriverIds)
      ? [...order.rejectedDriverIds]
      : [];
    if (!rejected.includes(driverId)) rejected.push(driverId);

    tx.update(orderRef, {
      rejectedDriverIds: rejected,
      offeredDriverId: FieldValue.delete(),
      deliveryPhase: "unassigned",
      assignmentStatus: "searching",
      deliveryAcceptDeadline: FieldValue.delete(),
      offeredAt: FieldValue.delete(),
      deliveryRejectReason: reason || "rejected",
      updatedAt: FieldValue.serverTimestamp(),
    });

    const driverRef = db.collection("users").doc(driverId);
    const driverSnap = await tx.get(driverRef);
    if (driverSnap.exists) {
      applyRejectCooldownTx(tx, driverRef, driverSnap.data());
    }

    return {
      ok: true,
      orderId,
      round: order.assignmentRound || 1,
      rejectedDriverIds: rejected,
    };
  });

  await enqueueAssignRoundJob(db, orderId, result.round);
  return result;
}

/**
 * Timeout expired offer — same as reject path with timeout reason.
 */
async function timeoutOfferForOrder(db, orderId, config) {
  const orderRef = db.collection("orders").doc(orderId);

  const result = await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) return { skipped: true, reason: "not_found" };
    const order = orderSnap.data();

    if (order.deliveryPhase !== "offered") {
      return { skipped: true, reason: "not_offered" };
    }
    if (!isDeadlinePassed(order.deliveryAcceptDeadline)) {
      return { skipped: true, reason: "deadline_not_passed" };
    }

    const driverId = order.offeredDriverId;
    // Timeout is not a permanent reject — driver may have missed the push/UI.
    const rejected = Array.isArray(order.rejectedDriverIds)
      ? [...order.rejectedDriverIds]
      : [];

    tx.update(orderRef, {
      rejectedDriverIds: rejected,
      offeredDriverId: FieldValue.delete(),
      deliveryPhase: "unassigned",
      assignmentStatus: "searching",
      deliveryAcceptDeadline: FieldValue.delete(),
      offeredAt: FieldValue.delete(),
      deliveryRejectReason: "timeout",
      updatedAt: FieldValue.serverTimestamp(),
    });

    if (driverId) {
      const driverRef = db.collection("users").doc(driverId);
      tx.update(driverRef, {
        noResponseCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    return {
      ok: true,
      orderId,
      round: order.assignmentRound || 1,
      driverId,
    };
  });

  if (result.ok) {
    await enqueueAssignRoundJob(db, orderId, result.round);
  }
  return result;
}

async function enqueueAssignRoundJob(db, orderId, round, operationId) {
  const payload = { orderId, round };
  if (typeof operationId === "string" && operationId.length > 0) {
    payload.operationId = operationId;
  }
  await db.collection("job_queue").add({
    type: "assignOrderRound",
    status: "pending",
    priority: "high",
    payload,
    createdAt: FieldValue.serverTimestamp(),
    attempts: 0,
  });
}

/**
 * Clear active order lock on driver — delivered / cancel / admin force.
 */
async function clearActiveOrderLock(db, { driverId, orderId, actorUid, reason }) {
  const driverRef = db.collection("users").doc(driverId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(driverRef);
    if (!snap.exists) return;
    const data = snap.data();
    if (orderId && data.activeOrderId && data.activeOrderId !== orderId) {
      throw new HttpsError("failed-precondition", "ORDER_LOCK_MISMATCH");
    }
    tx.update(driverRef, {
      activeOrderId: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  await writeAuditLog(db, {
    type: "active_order_released",
    actorUid,
    targetType: "user",
    targetId: driverId,
    details: { orderId, reason },
  });
}

module.exports = {
  generateOperationId,
  isDeadlinePassed,
  checkAcceptEligibility,
  driverHasActiveDeliveryQuery,
  acceptOffer,
  rejectOffer,
  timeoutOfferForOrder,
  enqueueAssignRoundJob,
  clearActiveOrderLock,
};
