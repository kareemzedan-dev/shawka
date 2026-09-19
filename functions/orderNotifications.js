const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");
const { logOpsIncident } = require("./shared/opsIncidents");

function extractToken(data) {
  const token = data?.fcmToken;
  return typeof token === "string" && token.length > 10 ? token : null;
}

/** إشعارات تلقائية عند تغيّر حالة الطلب. */
const STATUS_PUSH = {
  preparing: {
    title: "جاري تحضير طلبك 👨‍🍳",
    body: (order) => {
      const store = order.storeName || "المتجر";
      return `طلبك من ${store} قيد التحضير الآن`;
    },
  },
  readyForPickup: {
    title: "طلبك جاهز للاستلام 🟢",
    body: (order) => {
      const store = order.storeName || "المتجر";
      return `طلبك من ${store} جاهز — تعالى للاستلام`;
    },
  },
  onTheWay: {
    title: "طلبك في الطريق إليك 🛵",
    body: (order) => {
      const store = order.storeName || "المتجر";
      return `المندوب في الطريق بطلبك من ${store}`;
    },
  },
  outForDelivery: {
    title: "طلبك في الطريق إليك 🛵",
    body: (order) => {
      const store = order.storeName || "المتجر";
      return `المندوب في الطريق بطلبك من ${store}`;
    },
  },
  delivered: {
    title: "تم توصيل طلبك ✅",
    body: (order) => {
      const store = order.storeName || "المتجر";
      return `تم تسليم طلبك من ${store} بنجاح — بالهنا والشفا`;
    },
  },
  cancelled: {
    title: "تم إلغاء الطلب",
    body: (order) => {
      const store = order.storeName || "المتجر";
      return `تم إلغاء طلبك من ${store}. لو عندك استفسار تواصل مع الدعم`;
    },
  },
};

exports.notifyOrderStatusChange = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const prevStatus = before.status;
    const nextStatus = after.status;
    if (!nextStatus || prevStatus === nextStatus) return;

    const template = STATUS_PUSH[nextStatus];
    if (!template) return;

    const customerId = after.customerId;
    if (typeof customerId !== "string" || customerId.length < 8) {
      logger.info("Order status push skipped — no customerId", {
        orderId: event.params.orderId,
        status: nextStatus,
      });
      return;
    }

    const db = getFirestore();
    const userDoc = await db.collection("users").doc(customerId).get();
    if (!userDoc.exists) return;

    const orderId = event.params.orderId;
    const messaging = getMessaging();
    const bodyText = template.body(after);
    const token = extractToken(userDoc.data());

    // دائماً نكتب داخل التطبيق — حتى بدون FCM token.
    try {
      await db
        .collection("users")
        .doc(customerId)
        .collection("notifications")
        .add({
          title: template.title,
          body: bodyText,
          type: "order_status",
          deepLink: "order",
          deepLinkId: orderId,
          orderId,
          orderStatus: nextStatus,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });
    } catch (err) {
      logger.warn("In-app notification write failed", {
        orderId,
        error: String(err),
      });
    }

    if (!token) {
      logger.info("Order status push skipped — no FCM token", {
        orderId,
        customerId,
        status: nextStatus,
      });
      return;
    }

    try {
      await messaging.send({
        token,
        notification: {
          title: template.title,
          body: bodyText,
        },
        data: {
          type: "order_status",
          deepLink: "order",
          deepLinkId: orderId,
          orderId,
          orderStatus: nextStatus,
          inboxWritten: "1",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "matlobgo_orders",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: { sound: "default", category: "MATLOBGO_DEEP_LINK" },
          },
        },
      });
      logger.info("Order status push sent", {
        orderId,
        customerId,
        status: nextStatus,
      });
    } catch (error) {
      logger.error("Order status push failed", {
        orderId,
        customerId,
        status: nextStatus,
        error: String(error),
      });
      await logOpsIncident(db, {
        type: "fcm_order_status_failed",
        severity: "error",
        message: `فشل FCM لحالة الطلب ${nextStatus}`,
        orderId,
        details: { customerId, error: String(error) },
      });
    }
  },
);
