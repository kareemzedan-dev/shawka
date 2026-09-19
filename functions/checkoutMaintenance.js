const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const cleanupCheckoutRequests = onSchedule(
  {
    region: "us-central1",
    schedule: "every 24 hours",
    timeZone: "Africa/Cairo",
  },
  async () => {
    const db = getFirestore();
    while (true) {
      const expired = await db
        .collection("checkout_requests")
        .where("expiresAt", "<=", Timestamp.now())
        .limit(400)
        .get();
      if (expired.empty) return;
      const batch = db.batch();
      for (const doc of expired.docs) batch.delete(doc.ref);
      await batch.commit();
      if (expired.size < 400) return;
    }
  },
);

module.exports = { cleanupCheckoutRequests };
