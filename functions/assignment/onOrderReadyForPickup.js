const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { generateOperationId } = require("./offerManager");
const { runAssignOrderRound } = require("./assignOrderRoundCore");

async function handleOrderReadyForPickup(db, orderId, before, after) {
  if (!after) return { skipped: true, reason: "missing_data" };
  if (before && before.status === after.status) {
    return { skipped: true, reason: "same_status" };
  }
  if (after.status !== "readyForPickup") return { skipped: true, reason: "not_ready" };

  // لوحة التحكم تدير التوصيل يدوياً بدون تطبيق سائق.
  if (
    after.skipDriverAssignment === true ||
    after.fulfillmentMode === "admin"
  ) {
    return { skipped: true, reason: "admin_fulfillment" };
  }

  if (after.deliveryId) {
    logger.info("onOrderReadyForPickup: already assigned", { orderId });
    return { skipped: true, reason: "already_assigned" };
  }

  if (after.assignmentStatus === "accepted") return { skipped: true, reason: "accepted" };

  // Allow restart when previously failed, or when stuck searching without an active offer.
  const hasLiveOffer =
    after.deliveryPhase === "offered" &&
    typeof after.offeredDriverId === "string" &&
    after.offeredDriverId.length > 0;
  if (hasLiveOffer) {
    return { skipped: true, reason: "already_started" };
  }
  if (
    (after.assignmentStatus === "searching" ||
      after.assignmentStatus === "offering") &&
    before &&
    before.status === "readyForPickup"
  ) {
    // Same ready status re-write while already searching — skip.
    return { skipped: true, reason: "already_started" };
  }
  if (after.status === "cancelled" || after.deliveryPhase === "cancelled") {
    return { skipped: true, reason: "cancelled" };
  }

  const orderRef = db.collection("orders").doc(orderId);
  const operationId = generateOperationId();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (!snap.exists) return;
    const order = snap.data();

    if (order.deliveryId || order.assignmentStatus === "accepted") return;
    if (order.status !== "readyForPickup") return;

    tx.update(orderRef, {
      assignmentStatus: "searching",
      deliveryPhase: "unassigned",
      assignmentRound: 1,
      rejectedDriverIds: [],
      offeredDriverId: FieldValue.delete(),
      deliveryAcceptDeadline: FieldValue.delete(),
      offeredAt: FieldValue.delete(),
      assignmentOperationId: operationId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const jobRef = db.collection("job_queue").doc();
    tx.set(jobRef, {
      type: "assignOrderRound",
      status: "pending",
      priority: "high",
      payload: { orderId, round: 1, operationId },
      createdAt: FieldValue.serverTimestamp(),
      attempts: 0,
    });
  });

  try {
    await runAssignOrderRound(db, { orderId, round: 1, operationId });
  } catch (err) {
    logger.warn("assignment_immediate_round_failed", {
      orderId,
      error: String(err),
    });
  }

  logger.info("assignment_started", {
    orderId,
    governorate: after.governorate,
  });

  return { ok: true, orderId };
}

const onOrderReadyForPickup = onDocumentUpdated(
  { document: "orders/{orderId}", region: FUNCTIONS_REGION },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const db = getFirestore();
    await handleOrderReadyForPickup(db, event.params.orderId, before, after);
  },
);

const onOrderCreatedForAssignment = onDocumentCreated(
  { document: "orders/{orderId}", region: FUNCTIONS_REGION },
  async (event) => {
    const after = event.data?.data();
    if (!after) return;

    // Assignment starts only when status is explicitly readyForPickup (admin panel).
    if (after.status === "readyForPickup") {
      const db = getFirestore();
      await handleOrderReadyForPickup(db, event.params.orderId, null, after);
    }
  },
);

module.exports = {
  onOrderReadyForPickup,
  onOrderCreatedForAssignment,
  handleOrderReadyForPickup,
};
