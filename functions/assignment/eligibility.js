const { getConfig } = require("../shared/config");
const { extractLatLng } = require("../shared/geohash");
const { isOnOfferCooldown } = require("../shared/driverCooldown");
const { isCashBlockedUser } = require("../shared/driverWallet");

const TERMINAL_PHASES = new Set(["delivered", "cancelled"]);

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts === "number") return ts;
  if (ts instanceof Date) return ts.getTime();
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (typeof ts.toDate === "function") return ts.toDate().getTime();
  return null;
}

function hasActiveOrderLock(user) {
  const id = user.activeOrderId;
  return typeof id === "string" && id.length > 0;
}

function isGpsEligible(user, nowMs = Date.now(), config) {
  if (user.gpsTrustStatus === "suspended") return false;

  const trust = user.gpsTrustStatus || "trusted";
  if (trust === "trusted") return true;

  if (trust === "restricted") {
    const eligibleUntil = toMillis(user.assignmentEligibleUntil);
    if (eligibleUntil != null && eligibleUntil > nowMs) return false;
    return true;
  }

  const count24h =
    typeof user.gpsViolationCount24h === "number" ? user.gpsViolationCount24h : 0;
  if (count24h >= 3) {
    const until = toMillis(user.assignmentEligibleUntil);
    if (until != null && until > nowMs) return false;
  }

  return true;
}

function isDriverApproved(user) {
  const status = user.driverApprovalStatus;
  if (status === "approved") return true;
  if (
    status === "rejected" ||
    status === "suspended" ||
    status === "pending"
  ) {
    return false;
  }
  // Legacy admin-created drivers may omit driverApprovalStatus.
  return user.isActive !== false;
}

function isPresenceOnline(user, nowMs = Date.now(), config) {
  const cfg = config || getConfig();
  if (user.isDriverOnline !== true) return false;
  if (!isDriverApproved(user)) return false;
  if (user.isActive === false) return false;

  const heartbeatMs = toMillis(user.heartbeatAt);
  const lastActiveMs = toMillis(user.lastActiveAt);
  const offlineThresholdMs = cfg.driver_presence_offline_threshold_seconds * 1000;
  const freshestPresenceMs = Math.max(heartbeatMs ?? 0, lastActiveMs ?? 0);
  if (
    freshestPresenceMs > 0 &&
    nowMs - freshestPresenceMs > offlineThresholdMs &&
    user.isDriverOnline !== true
  ) {
    return false;
  }

  const locationMs =
    toMillis(user.locationUpdatedAt) ?? toMillis(user.lastValidLocationAt);
  const staleThresholdMs = cfg.driver_presence_location_stale_seconds * 1000;
  if (locationMs == null || nowMs - locationMs > staleThresholdMs) {
    const coords = extractLatLng(user);
    if (coords && user.isDriverOnline === true) {
      return true;
    }
    // Online toggle on — still assignable; coords resolved at offer time.
    return freshestPresenceMs > 0 || user.isDriverOnline === true;
  }

  return true;
}

function resolveAssignmentCoords(user, orderContext) {
  const direct = extractLatLng(user);
  if (direct) return direct;

  if (
    user.isDriverOnline === true &&
    orderContext &&
    typeof orderContext.governorate === "string" &&
    orderContext.governorate.length > 0 &&
    user.governorate === orderContext.governorate &&
    typeof orderContext.storeLat === "number" &&
    typeof orderContext.storeLng === "number"
  ) {
    return { lat: orderContext.storeLat, lng: orderContext.storeLng };
  }

  return null;
}

/**
 * Full assignment eligibility check — §9.2 + §11.1.5 + §11.2.3.
 */
function isAssignmentEligible(user, nowMs = Date.now(), config, orderContext) {
  if (isCashBlockedUser(user)) {
    return { eligible: false, reason: "cash_blocked" };
  }
  if (!isPresenceOnline(user, nowMs, config)) {
    return { eligible: false, reason: "presence" };
  }
  if (!isGpsEligible(user, nowMs, config)) {
    return { eligible: false, reason: "gps_trust" };
  }
  if (hasActiveOrderLock(user)) {
    return { eligible: false, reason: "active_order_lock" };
  }
  if (isOnOfferCooldown(user, nowMs)) {
    return { eligible: false, reason: "offer_cooldown" };
  }

  const coords = resolveAssignmentCoords(user, orderContext);
  if (!coords) return { eligible: false, reason: "no_location" };

  return { eligible: true, coords };
}

function isOfferAcceptEligible(user, nowMs = Date.now(), config) {
  if (isCashBlockedUser(user)) {
    return { eligible: false, reason: "cash_blocked" };
  }
  if (!isDriverApproved(user) || user.isActive === false) {
    return { eligible: false, reason: "not_approved" };
  }
  if (hasActiveOrderLock(user)) {
    return { eligible: false, reason: "active_order_lock" };
  }
  return { eligible: true };
}

module.exports = {
  TERMINAL_PHASES,
  hasActiveOrderLock,
  isDriverApproved,
  isGpsEligible,
  isPresenceOnline,
  isAssignmentEligible,
  isOfferAcceptEligible,
  resolveAssignmentCoords,
  isCashBlockedUser,
  toMillis,
};
