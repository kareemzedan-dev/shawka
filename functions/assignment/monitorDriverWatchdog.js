const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { toMillis } = require("./eligibility");
const { logOpsIncident } = require("../shared/opsIncidents");
const { logSystemAnalyticsEvent } = require("../shared/systemAnalytics");

const WARNING_MS = 5 * 60 * 1000;
const CRITICAL_MS = 10 * 60 * 1000;
const ACTIVE_PHASES = ["accepted", "picked_up", "outForDelivery", "in_transit"];

function lastActivityMs(driver) {
  const hb = toMillis(driver.heartbeatAt);
  const loc = toMillis(driver.locationUpdatedAt);
  if (hb == null && loc == null) return null;
  if (hb == null) return loc;
  if (loc == null) return hb;
  return Math.max(hb, loc);
}

/**
 * Driver Watchdog — warning/critical incidents when driver goes stale mid-delivery.
 */
const monitorDriverWatchdog = onSchedule(
  { schedule: "every 2 minutes", region: FUNCTIONS_REGION },
  async () => {
    const db = getFirestore();
    const now = Date.now();

    for (const phase of ACTIVE_PHASES) {
      const snap = await db
        .collection("orders")
        .where("deliveryPhase", "==", phase)
        .limit(40)
        .get();

      for (const doc of snap.docs) {
        const order = doc.data();
        const orderId = doc.id;
        const driverId = order.deliveryId;
        if (!driverId || order.status === "cancelled" || order.status === "delivered") {
          continue;
        }

        const driverSnap = await db.collection("users").doc(driverId).get();
        if (!driverSnap.exists) continue;
        const driver = driverSnap.data();

        const lastMs = lastActivityMs(driver);
        const idleMs = lastMs == null ? CRITICAL_MS + 1 : now - lastMs;

        if (idleMs < WARNING_MS) {
          if (order.watchdogWarningAt || order.watchdogCriticalAt) {
            await doc.ref.update({
              watchdogWarningAt: FieldValue.delete(),
              watchdogCriticalAt: FieldValue.delete(),
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
          continue;
        }

        const orderRef = doc.ref;

        if (idleMs >= WARNING_MS && !order.watchdogWarningAt) {
          await orderRef.update({
            watchdogWarningAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          await logOpsIncident(db, {
            type: "driver_inactive",
            severity: "warning",
            message: `المندوب ${driver.name || driverId.slice(0, 8)} بدون نشاط ${Math.round(idleMs / 60000)} د`,
            orderId,
            driverId,
            details: {
              idleMs,
              deliveryPhase: phase,
              heartbeatAt: toMillis(driver.heartbeatAt),
              locationUpdatedAt: toMillis(driver.locationUpdatedAt),
            },
          });
          await logSystemAnalyticsEvent(db, {
            event: "driver_watchdog_warning",
            screen: "driver_watchdog",
            metadata: { orderId, driverId, idleMs, phase },
          });
        }

        if (idleMs >= CRITICAL_MS && !order.watchdogCriticalAt) {
          await orderRef.update({
            watchdogCriticalAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          await logOpsIncident(db, {
            type: "driver_unresponsive",
            severity: "critical",
            message: `المندوب ${driver.name || driverId.slice(0, 8)} غير مستجيب ${Math.round(idleMs / 60000)} د`,
            orderId,
            driverId,
            details: {
              idleMs,
              deliveryPhase: phase,
              heartbeatAt: toMillis(driver.heartbeatAt),
              locationUpdatedAt: toMillis(driver.locationUpdatedAt),
            },
          });
          await logSystemAnalyticsEvent(db, {
            event: "driver_watchdog_critical",
            screen: "driver_watchdog",
            metadata: { orderId, driverId, idleMs, phase },
          });
        }
      }
    }

    logger.info("monitorDriverWatchdog: cycle complete");
  },
);

module.exports = { monitorDriverWatchdog };
