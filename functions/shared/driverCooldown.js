const { FieldValue, Timestamp } = require("firebase-admin/firestore");

const COOLDOWN_MS = 10 * 60 * 1000;
const REJECT_WINDOW_MS = 30 * 60 * 1000;
const MAX_CONSECUTIVE_REJECTS = 3;

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts === "number") return ts;
  if (ts instanceof Date) return ts.getTime();
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (typeof ts.toDate === "function") return ts.toDate().getTime();
  return null;
}

function isOnOfferCooldown(user, nowMs = Date.now()) {
  const until = toMillis(user.offerCooldownUntil);
  return until != null && until > nowMs;
}

/** Transaction-safe — driver explicitly rejected an offer. */
function applyRejectCooldownTx(tx, driverRef, driver, nowMs = Date.now()) {
  const lastRejectMs = toMillis(driver.lastRejectAt);
  let consecutive =
    lastRejectMs != null && nowMs - lastRejectMs <= REJECT_WINDOW_MS
      ? (typeof driver.consecutiveRejects === "number"
          ? driver.consecutiveRejects
          : 0) + 1
      : 1;

  const update = {
    consecutiveRejects: consecutive,
    lastRejectAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (consecutive >= MAX_CONSECUTIVE_REJECTS) {
    update.offerCooldownUntil = Timestamp.fromMillis(nowMs + COOLDOWN_MS);
    update.consecutiveRejects = 0;
  }

  tx.update(driverRef, update);
}

function resetRejectStreakTx(tx, driverRef) {
  tx.update(driverRef, {
    consecutiveRejects: 0,
    lastRejectAt: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

module.exports = {
  COOLDOWN_MS,
  isOnOfferCooldown,
  applyRejectCooldownTx,
  resetRejectStreakTx,
};
