const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULTS,
  computeWalletStatus,
  isDriverCashBlocked,
  pickNumber,
} = require("../shared/walletThresholds");

describe("walletThresholds", () => {
  it("computeWalletStatus uses threshold bands", () => {
    const t = { warningLevel1: 300, warningLevel2: 450, blockLevel: 500 };
    assert.equal(computeWalletStatus(0, t), "regular");
    assert.equal(computeWalletStatus(300, t), "needs_attention");
    assert.equal(computeWalletStatus(450, t), "near_block");
    assert.equal(computeWalletStatus(500, t), "blocked");
  });

  it("isDriverCashBlocked at block level", () => {
    const t = { blockLevel: 500 };
    assert.equal(isDriverCashBlocked(499, t), false);
    assert.equal(isDriverCashBlocked(500, t), true);
  });

  it("pickNumber prefers first matching V2 key", () => {
    assert.equal(
      pickNumber(
        { walletWarningThreshold: 250, warningLevel1: 300 },
        ["walletWarningThreshold", "warningLevel1"],
        DEFAULTS.warningLevel1,
      ),
      250,
    );
  });

  it("DEFAULTS include V2 settlement window and risk keys", () => {
    assert.equal(DEFAULTS.settlementWindowHours, 48);
    assert.equal(DEFAULTS.financialRiskBlockCount, 3);
    assert.equal(DEFAULTS.financialRiskOutstandingViolations, 5);
  });
});
