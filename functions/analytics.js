const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("./rateLimit");

const VALID_TYPES = new Set([
  "appOpen",
  "sessionStart",
  "sessionEnd",
  "screenView",
  "storeView",
  "productView",
  "addToCart",
  "removeFromCart",
  "cartOpen",
  "cartQuantityChange",
  "applyCoupon",
  "removeCoupon",
  "continueToCheckout",
  "addSuggestionToCart",
  "freeDeliveryUnlocked",
  "checkoutStart",
  "orderPlaced",
  "favoriteToggle",
  "productShare",
  "productQuantityChange",
  "ordersOpen",
  "orderExpand",
  "orderTrack",
  "orderReorder",
  "orderRate",
  "orderCancel",
  "orderInvoice",
]);

async function upsertSession(db, uid, type, metadata) {
  const sessionId = metadata?.sessionId;
  if (!sessionId || typeof sessionId !== "string") return;

  const ref = db.collection("analytics_sessions").doc(sessionId);
  if (type === "sessionStart") {
    await ref.set(
      {
        userId: uid,
        sessionId,
        startedAt: FieldValue.serverTimestamp(),
        eventCount: 1,
        screens: [],
      },
      { merge: true },
    );
    return;
  }

  if (type === "sessionEnd") {
    const durationSeconds =
      typeof metadata.durationSeconds === "number"
        ? metadata.durationSeconds
        : 0;
    const eventCount =
      typeof metadata.eventCount === "number" ? metadata.eventCount : 0;
    await ref.set(
      {
        userId: uid,
        sessionId,
        endedAt: FieldValue.serverTimestamp(),
        durationSeconds,
        eventCount,
        endReason:
          typeof metadata.reason === "string" ? metadata.reason : "unknown",
      },
      { merge: true },
    );
  }
}

/**
 * تتبع Analytics عبر السيرفر — Rate Limited (120 حدث / دقيقة / مستخدم).
 */
const trackAnalyticsEvent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  await checkRateLimit(db, `analytics:${uid}`, 120, 60 * 1000);

  const data = request.data || {};
  const type = data.type;
  const screen = typeof data.screen === "string" ? data.screen.slice(0, 80) : "";
  const label = typeof data.label === "string" ? data.label.slice(0, 200) : "";

  if (!VALID_TYPES.has(type)) {
    throw new HttpsError("invalid-argument", "نوع الحدث غير صالح.");
  }
  if (screen.length === 0) {
    throw new HttpsError("invalid-argument", "screen مطلوب.");
  }

  const userName =
    typeof data.userName === "string" ? data.userName.slice(0, 120) : "";
  const metadata =
    data.metadata && typeof data.metadata === "object" ? data.metadata : {};

  await db.collection("analytics_events").add({
    userId: uid,
    userName,
    type,
    screen,
    label,
    storeId: typeof data.storeId === "string" ? data.storeId.slice(0, 80) : "",
    storeName:
      typeof data.storeName === "string" ? data.storeName.slice(0, 120) : "",
    productId:
      typeof data.productId === "string" ? data.productId.slice(0, 80) : "",
    productName:
      typeof data.productName === "string" ? data.productName.slice(0, 120) : "",
    metadata,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (type === "sessionStart" || type === "sessionEnd") {
    await upsertSession(db, uid, type, metadata);
  }

  if (type === "screenView" && metadata.sessionId) {
    const sessionRef = db
      .collection("analytics_sessions")
      .doc(String(metadata.sessionId));
    await sessionRef.set(
      {
        screens: FieldValue.arrayUnion([screen]),
        lastScreen: screen,
        lastEventAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  return { ok: true };
});

module.exports = { trackAnalyticsEvent };
