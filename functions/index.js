const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
  FieldPath,
  Timestamp,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("./shared/region");

// Runtime defaults for Gen2 — must run before any function module is required.
// Intentionally omits maxInstances: 1 (not safe for production traffic capacity).
setGlobalOptions({
  region: FUNCTIONS_REGION,
  memory: "256MiB",
  cpu: "gcf_gen1",
});

const {
  syncAuthClaimsOnUserWrite,
  refreshAuthClaims,
  adminSetStaffRole,
  adminAssignStoreOwner,
  adminRemoveStoreOwner,
} = require("./authClaims");
const { trackAnalyticsEvent } = require("./analytics");
const {
  createCustomerOrders,
  previewCustomerCheckout,
} = require("./customerOrders");
const { validateCartCoupon } = require("./cartCoupons");
const { cleanupCheckoutRequests } = require("./checkoutMaintenance");
const { submitDriverRating } = require("./driverRating");
const { adminCreateDeliveryUser } = require("./deliveryUsers");
const {
  processJobQueue,
  processJobOnCreate,
} = require("./jobQueue");
const { notifyOrderStatusChange } = require("./orderNotifications");
const {
  onOrderReadyForPickup,
  onOrderCreatedForAssignment,
} = require("./assignment/onOrderReadyForPickup");
const { onDriverOnlineForAssignment } = require("./assignment/onDriverOnlineForAssignment");
const { notifyDriverOffer } = require("./assignment/notifyDriverOffer");
const { assignOrderRound } = require("./assignment/assignOrderRound");
const { respondToOffer } = require("./assignment/respondToOffer");
const { timeoutOffer } = require("./assignment/timeoutOffer");
const { cancelOrder } = require("./assignment/cancelOrder");
const { adminReassignDelivery } = require("./assignment/adminReassignDelivery");
const { driverRegister } = require("./driver/driverRegister");
const { advanceDeliveryPhase } = require("./driver/advanceDeliveryPhase");
const { adminReviewDriver } = require("./driver/adminReviewDriver");
const { adminReviewCustomer } = require("./customer/adminReviewCustomer");
const { adminDeleteCustomer } = require("./customer/adminDeleteCustomer");
const { deleteMyAccount } = require("./customer/deleteMyAccount");
const { adminCreateStaffUser } = require("./customer/adminCreateStaffUser");
const { adminResetDriverGpsTrust } = require("./driver/adminResetDriverGpsTrust");
const { adminForceReleaseActiveOrder } = require("./driver/adminForceReleaseActiveOrder");
const { adminWalletSettlement } = require("./driver/adminWalletSettlement");
const {
  submitSettlementRequest,
  reviewSettlementRequest,
} = require("./driver/settlementRequests");
const { financialRiskMonitor } = require("./driver/financialRiskMonitor");
const { walletDueDateNotifier } = require("./driver/walletDueDateNotifier");
const { onDriverLocationWrite } = require("./driver/onDriverLocationWrite");
const { validateDriverLocation } = require("./driver/validateDriverLocation");
const { refreshDriverMarketStats } = require("./driver/refreshDriverMarketStats");
const { monitorStaleAssignments } = require("./assignment/monitorStaleAssignments");
const { monitorDriverWatchdog } = require("./assignment/monitorDriverWatchdog");
const { onFavoriteWrite } = require("./favorites");
const { onReviewWrite, toggleReviewHelpful } = require("./reviews");
const {
  sendCustomerPhoneOtp,
  verifyCustomerPhoneOtp,
} = require("./customer/phoneOtp");
const { setCustomerCredentials } = require("./customer/setCustomerCredentials");
const { completeCustomerProfile } = require("./customer/completeCustomerProfile");

initializeApp();

exports.syncAuthClaimsOnUserWrite = syncAuthClaimsOnUserWrite;
exports.refreshAuthClaims = refreshAuthClaims;
exports.adminSetStaffRole = adminSetStaffRole;
exports.adminAssignStoreOwner = adminAssignStoreOwner;
exports.adminRemoveStoreOwner = adminRemoveStoreOwner;
exports.trackAnalyticsEvent = trackAnalyticsEvent;
exports.createCustomerOrders = createCustomerOrders;
exports.previewCustomerCheckout = previewCustomerCheckout;
exports.validateCartCoupon = validateCartCoupon;
exports.cleanupCheckoutRequests = cleanupCheckoutRequests;
exports.submitDriverRating = submitDriverRating;
exports.adminCreateDeliveryUser = adminCreateDeliveryUser;
exports.processJobQueue = processJobQueue;
exports.processJobOnCreate = processJobOnCreate;
exports.notifyOrderStatusChange = notifyOrderStatusChange;
exports.onOrderReadyForPickup = onOrderReadyForPickup;
exports.onOrderCreatedForAssignment = onOrderCreatedForAssignment;
exports.onDriverOnlineForAssignment = onDriverOnlineForAssignment;
exports.notifyDriverOffer = notifyDriverOffer;
exports.assignOrderRound = assignOrderRound;
exports.respondToOffer = respondToOffer;
exports.timeoutOffer = timeoutOffer;
exports.cancelOrder = cancelOrder;
exports.adminReassignDelivery = adminReassignDelivery;
exports.driverRegister = driverRegister;
exports.advanceDeliveryPhase = advanceDeliveryPhase;
exports.adminReviewDriver = adminReviewDriver;
exports.adminReviewCustomer = adminReviewCustomer;
exports.adminDeleteCustomer = adminDeleteCustomer;
exports.deleteMyAccount = deleteMyAccount;
exports.adminCreateStaffUser = adminCreateStaffUser;
exports.sendCustomerPhoneOtp = sendCustomerPhoneOtp;
exports.verifyCustomerPhoneOtp = verifyCustomerPhoneOtp;
exports.setCustomerCredentials = setCustomerCredentials;
exports.completeCustomerProfile = completeCustomerProfile;
exports.adminResetDriverGpsTrust = adminResetDriverGpsTrust;
exports.adminForceReleaseActiveOrder = adminForceReleaseActiveOrder;
exports.adminWalletSettlement = adminWalletSettlement;
exports.submitSettlementRequest = submitSettlementRequest;
exports.reviewSettlementRequest = reviewSettlementRequest;
exports.financialRiskMonitor = financialRiskMonitor;
exports.walletDueDateNotifier = walletDueDateNotifier;
exports.onDriverLocationWrite = onDriverLocationWrite;
exports.validateDriverLocation = validateDriverLocation;
exports.refreshDriverMarketStats = refreshDriverMarketStats;
exports.monitorStaleAssignments = monitorStaleAssignments;
exports.monitorDriverWatchdog = monitorDriverWatchdog;
exports.onFavoriteWrite = onFavoriteWrite;
exports.onReviewWrite = onReviewWrite;
exports.toggleReviewHelpful = toggleReviewHelpful;

const INACTIVE_DAYS = 30;
const MAX_SPECIFIC_USERS = 500;

function extractToken(data) {
  const token = data?.fcmToken;
  return typeof token === "string" && token.length > 10 ? token : null;
}

async function collectSpecificUserTargets(db, userIds) {
  if (!Array.isArray(userIds) || userIds.length === 0) return [];

  const targets = [];
  const slice = userIds.slice(0, MAX_SPECIFIC_USERS);

  await Promise.all(
    slice.map(async (uid) => {
      if (typeof uid !== "string" || uid.length < 8) return;
      const doc = await db.collection("users").doc(uid).get();
      if (!doc.exists) return;
      targets.push({
        uid,
        token: extractToken(doc.data()),
      });
    }),
  );

  return targets;
}

async function forEachUserTargetBatch(db, data, callback) {
  const target = data.target || "allUsers";
  const governorate = data.governorate || "";
  const activityTypeIds = Array.isArray(data.activityTypeIds)
    ? data.activityTypeIds.map((id) => String(id).trim()).filter(Boolean)
    : [];

  const matchesActivity = (userData) => {
    if (!activityTypeIds.length) return true;
    const userActivity = String(userData.activityTypeId || "").trim();
    if (!userActivity) return false;
    return activityTypeIds.includes(userActivity);
  };

  if (target === "specificUsers") {
    const targets = await collectSpecificUserTargets(
      db,
      data.targetUserIds || [],
    );
    // Re-fetch docs for activity filter when needed.
    let filtered = targets;
    if (activityTypeIds.length) {
      filtered = [];
      for (const t of targets) {
        const snap = await db.collection("users").doc(t.uid).get();
        if (snap.exists && matchesActivity(snap.data() || {})) {
          filtered.push(t);
        }
      }
    }
    if (filtered.length > 0) await callback(filtered);
    return;
  }

  let usersQuery = db.collection("users").where("role", "==", "customer");
  if (target === "governorate" && governorate) {
    usersQuery = usersQuery.where("governorate", "==", governorate);
  }
  const cutoff =
    target === "inactiveUsers"
      ? new Date(Date.now() - INACTIVE_DAYS * 24 * 60 * 60 * 1000)
      : null;
  let lastDoc = null;

  while (true) {
    let pageQuery = usersQuery.orderBy(FieldPath.documentId()).limit(500);
    if (lastDoc) pageQuery = pageQuery.startAfter(lastDoc);
    const snap = await pageQuery.get();
    if (snap.empty) break;

    const targets = snap.docs
      .filter((doc) => {
        const data = doc.data() || {};
        if (!matchesActivity(data)) return false;
        if (target !== "inactiveUsers") return true;
        const lastActive = data.lastActiveAt?.toDate?.();
        return !lastActive || lastActive < cutoff;
      })
      .map((doc) => ({
        uid: doc.id,
        token: extractToken(doc.data()),
      }));
    if (targets.length > 0) await callback(targets);

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < 500) break;
  }
}

async function writeInboxForUsers(db, userIds, payload) {
  for (let i = 0; i < userIds.length; i += 400) {
    const chunk = userIds.slice(i, i + 400);
    const batch = db.batch();
    for (const uid of chunk) {
      const ref = db.collection("users").doc(uid).collection("notifications").doc();
      batch.set(ref, payload);
    }
    await batch.commit();
  }
}

function buildFcmData(campaignId, data) {
  const target = data.target || "allUsers";
  const deepLink = data.deepLinkRoute || "home";
  const deepLinkId =
    typeof data.deepLinkId === "string" ? data.deepLinkId : "";

  return {
    campaignId,
    target,
    type: "campaign",
    deepLink,
    deepLinkId,
    inboxWritten: "1",
    click_action: "FLUTTER_NOTIFICATION_CLICK",
  };
}

async function dispatchCampaign(db, campaignId, data) {
  const campaignRef = db.collection("push_campaigns").doc(campaignId);
  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(campaignRef);
    if (!snap.exists) return false;
    const current = snap.data();
    if (current.dispatchState === "completed") return false;
    const leaseUntil = current.dispatchLeaseUntil?.toMillis?.() || 0;
    if (current.dispatchState === "processing" && leaseUntil > Date.now()) {
      return false;
    }
    tx.update(campaignRef, {
      dispatchState: "processing",
      dispatchLeaseUntil: Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
      dispatchStartedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claimed) {
    return { skipped: true, reason: "already_claimed" };
  }

  const title = data.title || "شوكة و سكينة";
  const body = data.body || "";

  const fcmData = buildFcmData(campaignId, data);
  const messaging = getMessaging();
  let targeted = 0;
  let success = 0;
  let failure = 0;
  let inboxWrites = 0;

  const inboxPayload = {
    title,
    body,
    type: "campaign",
    deepLink: fcmData.deepLink,
    deepLinkId: fcmData.deepLinkId || null,
    campaignId,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  };

  await forEachUserTargetBatch(db, data, async (targets) => {
    const uids = targets.map((t) => t.uid);
    try {
      await writeInboxForUsers(db, uids, inboxPayload);
      inboxWrites += uids.length;
    } catch (err) {
      logger.warn("Campaign inbox write failed", {
        campaignId,
        error: String(err),
      });
    }

    const tokens = targets.map((t) => t.token).filter(Boolean);
    for (let offset = 0; offset < tokens.length; offset += 500) {
      const chunk = tokens.slice(offset, offset + 500);
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: fcmData,
        android: {
          priority: "high",
          notification: {
            channelId: "matlobgo_general",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: { sound: "default", category: "MATLOBGO_DEEP_LINK" },
          },
        },
      });
      targeted += chunk.length;
      success += response.successCount;
      failure += response.failureCount;
    }
  });

  if (targeted === 0 && inboxWrites === 0) {
    logger.warn("No users found for campaign", campaignId);
    await campaignRef.update({
      status: "sent",
      dispatchState: "completed",
      dispatchLeaseUntil: FieldValue.delete(),
      sentAt: FieldValue.serverTimestamp(),
      tokensTargeted: 0,
      deliverySuccess: 0,
      deliveryFailure: 0,
      inboxWrites: 0,
      deliveryNote: "no_tokens",
    });
    return { success: 0, failure: 0, targeted: 0, inboxWrites: 0 };
  }

  await campaignRef.update({
    status: "sent",
    dispatchState: "completed",
    dispatchLeaseUntil: FieldValue.delete(),
    sentAt: FieldValue.serverTimestamp(),
    tokensTargeted: targeted,
    deliverySuccess: success,
    deliveryFailure: failure,
    inboxWrites,
    deliveryNote:
      targeted === 0
        ? "inbox_only"
        : failure === 0
          ? "ok"
          : success === 0
            ? "all_failed"
            : "partial",
  });

  logger.info("Push campaign dispatched", {
    campaignId,
    targeted,
    success,
    failure,
    inboxWrites,
    deepLink: fcmData.deepLink,
  });

  return {
    success,
    failure,
    targeted,
    inboxWrites,
  };
}

exports.dispatchPushCampaign = onDocumentCreated(
  "push_campaigns/{campaignId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    if (data.status !== "sent") {
      logger.info(
        "Campaign skipped — not sent status",
        event.params.campaignId,
      );
      return;
    }

    const db = getFirestore();
    try {
      await dispatchCampaign(db, event.params.campaignId, data);
    } catch (error) {
      await event.data.ref.set(
        {
          status: "failed",
          dispatchState: "failed",
          dispatchLeaseUntil: FieldValue.delete(),
          deliveryNote: "dispatch_error",
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      throw error;
    }
  },
);

exports.processScheduledPushCampaigns = onSchedule(
  "every 5 minutes",
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();

    const snap = await db
      .collection("push_campaigns")
      .where("status", "==", "scheduled")
      .where("scheduledAt", "<=", now)
      .limit(20)
      .get();

    if (snap.empty) {
      logger.info("No scheduled push campaigns due");
      return;
    }

    for (const doc of snap.docs) {
      try {
        await dispatchCampaign(db, doc.id, doc.data());
      } catch (error) {
        logger.error("Failed scheduled campaign", {
          campaignId: doc.id,
          error: String(error),
        });
      }
    }
  },
);
