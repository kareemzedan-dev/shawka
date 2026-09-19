const { FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

/**
 * Log operational incident for admin Live Incident Center.
 * Backward compatible — new collection, no breaking changes.
 */
async function logOpsIncident(db, {
  type,
  severity = "warning",
  message,
  orderId,
  driverId,
  details,
}) {
  try {
    await db.collection("ops_incidents").add({
      type: typeof type === "string" ? type : "unknown",
      severity,
      message: String(message || "").slice(0, 500),
      orderId: orderId || null,
      driverId: driverId || null,
      details: details || {},
      resolutionStatus: "open",
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    logger.warn("logOpsIncident failed", { type, error: String(err) });
  }
}

module.exports = { logOpsIncident };
