const { HttpsError } = require("firebase-functions/v2/https");
const { FieldValue } = require("firebase-admin/firestore");

/**
 * Rate limit باستخدام Firestore transactions — للـ Cloud Functions فقط.
 */
async function checkRateLimit(db, key, maxRequests, windowMs) {
  const ref = db.collection("rate_limits").doc(key);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();

    if (!snap.exists) {
      tx.set(ref, {
        count: 1,
        windowStart: now,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const data = snap.data();
    const windowStart = data.windowStart || 0;
    const count = data.count || 0;

    if (now - windowStart >= windowMs) {
      tx.set(ref, {
        count: 1,
        windowStart: now,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    if (count >= maxRequests) {
      throw new HttpsError(
        "resource-exhausted",
        "تم تجاوز حد الطلبات — حاول بعد قليل.",
      );
    }

    tx.update(ref, {
      count: count + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

module.exports = { checkRateLimit };
