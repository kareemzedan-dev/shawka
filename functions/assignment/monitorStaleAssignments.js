const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { clearActiveOrderLock, generateOperationId } = require("./offerManager");
const { runAssignOrderRound } = require("./assignOrderRoundCore");
const { logOpsIncident } = require("../shared/opsIncidents");

const STALE_MS = 3 * 60 * 1000;

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (typeof ts === "number") return ts;
  return null;
}

/**
 * Auto-reassign when driver accepted but went offline / stale before pickup.
 */
const monitorStaleAssignments = onSchedule(
  { schedule: "every 2 minutes", region: FUNCTIONS_REGION },
  async () => {
    const db = getFirestore();
    const now = Date.now();

    const snap = await db
      .collection("orders")
      .where("deliveryPhase", "==", "accepted")
      .limit(40)
      .get();

    for (const doc of snap.docs) {
      const order = doc.data();
      const orderId = doc.id;
      const driverId = order.deliveryId;
      if (!driverId || order.deliveryPickedUpAt) continue;
      if (order.status === "cancelled" || order.status === "delivered") continue;

      const driverSnap = await db.collection("users").doc(driverId).get();
      if (!driverSnap.exists) continue;
      const driver = driverSnap.data();

      const heartbeatMs = toMillis(driver.heartbeatAt);
      const locationMs = toMillis(driver.locationUpdatedAt);
      const gpsStale =
        locationMs == null || now - locationMs > STALE_MS;
      const stale =
        driver.isDriverOnline !== true ||
        heartbeatMs == null ||
        now - heartbeatMs > STALE_MS ||
        gpsStale;

      if (!stale) continue;

      logger.warn("monitorStaleAssignments: reassigning", { orderId, driverId });

      try {
        await clearActiveOrderLock(db, {
          driverId,
          orderId,
          actorUid: "system",
          reason: "driver_stale_auto_reassign",
        });
      } catch (e) {
        logger.warn("clear lock failed", { orderId, error: String(e) });
      }

      await db.collection("orders").doc(orderId).update({
        deliveryId: FieldValue.delete(),
        deliveryName: FieldValue.delete(),
        deliveryPhone: FieldValue.delete(),
        deliveryVehicleType: FieldValue.delete(),
        offeredDriverId: FieldValue.delete(),
        deliveryPhase: "unassigned",
        assignmentStatus: "searching",
        assignmentRound: 1,
        rejectedDriverIds: FieldValue.arrayUnion([driverId]),
        deliveryAcceptDeadline: FieldValue.delete(),
        offeredAt: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      const operationId = generateOperationId();
      try {
        await runAssignOrderRound(db, { orderId, round: 1, operationId });
      } catch (err) {
        logger.warn("reassign round failed", { orderId, error: String(err) });
      }

      await logOpsIncident(db, {
        type: "auto_reassign_stale_driver",
        severity: "warning",
        message: `إعادة تخصيص تلقائية — المندوب ${driverId.slice(0, 8)} offline/stale`,
        orderId,
        driverId,
        details: { heartbeatMs, locationMs, isDriverOnline: driver.isDriverOnline, gpsStale },
      });
    }
  },
);

module.exports = { monitorStaleAssignments };
