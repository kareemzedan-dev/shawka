const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { isDriverApproved } = require("./eligibility");
const { generateOperationId } = require("./offerManager");
const { runAssignOrderRound } = require("./assignOrderRoundCore");

async function retryFailedOrdersForDriver(db, driverId, driver) {
  const governorate = driver.governorate;
  if (typeof governorate !== "string" || governorate.length === 0) return;

  const snap = await db
    .collection("orders")
    .where("governorate", "==", governorate)
    .where("status", "==", "readyForPickup")
    .where("assignmentStatus", "==", "failed")
    .orderBy("createdAt", "desc")
    .limit(3)
    .get();

  for (const doc of snap.docs) {
    const order = doc.data();
    if (order.deliveryId || order.deliveryPhase === "offered") continue;

    const orderRef = doc.ref;
    const operationId = generateOperationId();
    await orderRef.update({
      assignmentStatus: "searching",
      deliveryPhase: "unassigned",
      assignmentRound: 1,
      rejectedDriverIds: [],
      deliveryRejectReason: FieldValue.delete(),
      candidateDriverIds: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    try {
      await runAssignOrderRound(db, {
        orderId: doc.id,
        round: 1,
        operationId,
      });
      logger.info("assignment_retry_on_driver_online", {
        orderId: doc.id,
        driverId,
        governorate,
      });
    } catch (err) {
      logger.warn("assignment_retry_on_driver_online_failed", {
        orderId: doc.id,
        driverId,
        error: String(err),
      });
    }
  }
}

const onDriverOnlineForAssignment = onDocumentUpdated(
  { document: "users/{uid}", region: FUNCTIONS_REGION },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after || after.role !== "delivery") return;

    const wasOnline = before?.isDriverOnline === true;
    const isOnline = after.isDriverOnline === true;
    if (wasOnline || !isOnline) return;
    if (!isDriverApproved(after)) return;

    const db = getFirestore();
    await retryFailedOrdersForDriver(db, event.params.uid, after);
  },
);

module.exports = { onDriverOnlineForAssignment, retryFailedOrdersForDriver };
