const { FieldValue } = require("firebase-admin/firestore");

/** Server-side analytics — bypasses client VALID_TYPES gate. */
async function logSystemAnalyticsEvent(db, { event, screen = "system", metadata = {} }) {
  try {
    await db.collection("analytics_events").add({
      userId: "system",
      userName: "system",
      type: "screenView",
      screen,
      label: event,
      metadata,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (_) {
    /* non-blocking */
  }
}

module.exports = { logSystemAnalyticsEvent };
