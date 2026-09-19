const DEFAULTS = Object.freeze({
  warningLevel1: 300,
  warningLevel2: 450,
  blockLevel: 500,
  settlementWindowHours: 48,
  financialRiskBlockCount: 3,
  financialRiskOutstandingViolations: 5,
});

function pickNumber(source, keys, fallback) {
  if (!source || typeof source !== "object") return fallback;
  for (const key of keys) {
    if (typeof source[key] === "number" && Number.isFinite(source[key])) {
      return source[key];
    }
  }
  return fallback;
}

/**
 * Load COD wallet thresholds from app_settings/config (remote-config ready).
 * Supports legacy keys (warningLevel1/2/blockLevel) and V2 RC keys.
 */
async function loadWalletThresholds(db) {
  try {
    const snap = await db.collection("app_settings").doc("config").get();
    const data = snap.exists ? snap.data() : {};
    const wallet = data.driverWallet || data.walletThresholds || {};
    const rc = data.remoteConfig || data.walletRemoteConfig || {};

    return {
      warningLevel1: pickNumber(
        { ...wallet, ...rc },
        ["walletWarningThreshold", "warningLevel1"],
        DEFAULTS.warningLevel1,
      ),
      warningLevel2: pickNumber(
        { ...wallet, ...rc },
        ["walletCriticalThreshold", "warningLevel2"],
        DEFAULTS.warningLevel2,
      ),
      blockLevel: pickNumber(
        { ...wallet, ...rc },
        ["walletBlockThreshold", "blockLevel"],
        DEFAULTS.blockLevel,
      ),
      settlementWindowHours: pickNumber(
        { ...wallet, ...rc },
        ["walletSettlementWindowHours", "settlementWindowHours"],
        DEFAULTS.settlementWindowHours,
      ),
      financialRiskBlockCount: pickNumber(
        { ...wallet, ...rc },
        ["financialRiskBlockCount"],
        DEFAULTS.financialRiskBlockCount,
      ),
      financialRiskOutstandingViolations: pickNumber(
        { ...wallet, ...rc },
        ["financialRiskOutstandingViolations"],
        DEFAULTS.financialRiskOutstandingViolations,
      ),
    };
  } catch (_) {
    return { ...DEFAULTS };
  }
}

function computeWalletStatus(outstandingBalance, thresholds) {
  const outstanding = Math.max(0, outstandingBalance || 0);
  const { warningLevel1, warningLevel2, blockLevel } = thresholds;

  if (outstanding >= blockLevel) return "blocked";
  if (outstanding >= warningLevel2) return "near_block";
  if (outstanding >= warningLevel1) return "needs_attention";
  return "regular";
}

function isDriverCashBlocked(outstandingBalance, thresholds) {
  return Math.max(0, outstandingBalance || 0) >= thresholds.blockLevel;
}

module.exports = {
  DEFAULTS,
  pickNumber,
  loadWalletThresholds,
  computeWalletStatus,
  isDriverCashBlocked,
};
