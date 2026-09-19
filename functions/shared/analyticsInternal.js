const { FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

/**
 * Server-side analytics — bypasses client VALID_TYPES gate.
 */
async function trackAnalyticsEventInternal(db, { type, userId, screen, metadata }) {
  try {
    await db.collection("analytics_events").add({
      userId: userId || null,
      userName: "",
      type: String(type).slice(0, 80),
      screen: String(screen || "system").slice(0, 80),
      label: "",
      storeId: "",
      storeName: "",
      productId: "",
      productName: "",
      metadata: metadata && typeof metadata === "object" ? metadata : {},
      source: "cloud_function",
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.warn("analytics_internal_failed", {
      type,
      error: String(error),
    });
  }
}

module.exports = { trackAnalyticsEventInternal };
