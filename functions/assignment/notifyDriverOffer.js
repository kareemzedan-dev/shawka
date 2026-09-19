const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { logOpsIncident } = require("../shared/opsIncidents");

function extractToken(data) {
  const token = data?.fcmToken;
  return typeof token === "string" && token.length > 10 ? token : null;
}

/**
 * Push + data message when a driver receives an incoming offer.
 */
const notifyDriverOffer = onDocumentUpdated(
  { document: "orders/{orderId}", region: FUNCTIONS_REGION },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after) return;

    if (after.deliveryPhase !== "offered") return;
    if (
      before?.deliveryPhase === "offered" &&
      before?.offeredDriverId === after.offeredDriverId
    ) {
      return;
    }

    const driverId = after.offeredDriverId;
    if (typeof driverId !== "string" || driverId.length < 8) return;

    const db = getFirestore();
    const driverSnap = await db.collection("users").doc(driverId).get();
    if (!driverSnap.exists) return;

    const token = extractToken(driverSnap.data());
    if (!token) {
      logger.info("driver_offer_push_skipped_no_token", {
        orderId: event.params.orderId,
        driverId,
      });
      return;
    }

    const orderId = event.params.orderId;
    const storeName =
      typeof after.storeName === "string" && after.storeName.length > 0
        ? after.storeName
        : "متجر";
    const fee =
      typeof after.deliveryFee === "number" ? after.deliveryFee : null;

    try {
      await getMessaging().send({
        token,
        notification: {
          title: "طلب توصيل جديد 🛵",
          body:
            fee != null
              ? `طلب من ${storeName} — أجر التوصيل ${fee} ج.م`
              : `طلب من ${storeName} — اضغط للقبول`,
        },
        data: {
          type: "new_offer",
          orderId,
          route: `/orders/incoming/${orderId}`,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "driver_offers",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              category: "MATLOBGO_DEEP_LINK",
              contentAvailable: true,
            },
          },
        },
      });
      logger.info("driver_offer_push_sent", { orderId, driverId });
    } catch (error) {
      logger.error("driver_offer_push_failed", {
        orderId,
        driverId,
        error: String(error),
      });
      await logOpsIncident(db, {
        type: "fcm_failure",
        severity: "warning",
        message: `فشل إرسال عرض توصيل للمندوب ${driverId.slice(0, 8)}`,
        orderId,
        driverId,
        details: { error: String(error) },
      });
    }
  },
);

module.exports = { notifyDriverOffer };
