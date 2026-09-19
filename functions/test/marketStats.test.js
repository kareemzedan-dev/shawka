const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeGovernorateId,
  computeActivityLevel,
  computeAvgWaitMinutes,
  buildMarketStatsDoc,
} = require("../shared/marketStats");

describe("marketStats", () => {
  it("normalizeGovernorateId slugifies names", () => {
    assert.equal(normalizeGovernorateId("Cairo"), "cairo");
    assert.equal(normalizeGovernorateId("  New Cairo  "), "new_cairo");
  });

  it("computeActivityLevel returns high for low wait + high offers", () => {
    const level = computeActivityLevel(
      { avgWaitMinutes: 3, offersLastHour: 25, onlineDriversApprox: 10 },
      {},
    );
    assert.equal(level, "high");
  });

  it("computeActivityLevel returns low for high wait", () => {
    const level = computeActivityLevel(
      { avgWaitMinutes: 12, offersLastHour: 15, onlineDriversApprox: 10 },
      {},
    );
    assert.equal(level, "low");
  });

  it("computeActivityLevel returns medium in between band", () => {
    const level = computeActivityLevel(
      { avgWaitMinutes: 5, offersLastHour: 10, onlineDriversApprox: 8 },
      {},
    );
    assert.equal(level, "medium");
  });

  it("computeAvgWaitMinutes uses default when sample too small", () => {
    assert.equal(computeAvgWaitMinutes([2, 3], {}), 5);
    assert.equal(computeAvgWaitMinutes([2, 4, 6], {}), 4);
  });

  it("buildMarketStatsDoc never high when wait exceeds threshold", () => {
    const doc = buildMarketStatsDoc({
      governorate: "Cairo",
      governorateId: "cairo",
      avgWaitMinutes: 10,
      onlineDriversApprox: 5,
      offersLastHour: 30,
      acceptsLastHour: 20,
      sampleSizeWait: 10,
      thresholdsUsed: {},
    });
    assert.equal(doc.activityLevel, "low");
  });
});
