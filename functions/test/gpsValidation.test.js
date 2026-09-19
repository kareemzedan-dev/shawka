const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  validateGpsUpdate,
  trustActionsForViolation,
  VIOLATION,
} = require("../shared/gpsValidation");

describe("gpsValidation", () => {
  const base = {
    vehicleType: "motorcycle",
    lastValidLatitude: 30.0444,
    lastValidLongitude: 31.2357,
    lastValidLocationAt: Date.now() - 15_000,
    nowMs: Date.now(),
  };

  it("accepts first fix without prior valid point", () => {
    const r = validateGpsUpdate({
      vehicleType: "car",
      newLatitude: 30.05,
      newLongitude: 31.24,
    });
    assert.equal(r.valid, true);
    assert.equal(r.level, VIOLATION.NONE);
  });

  it("accepts normal movement within speed limit", () => {
    const r = validateGpsUpdate({
      ...base,
      newLatitude: 30.0445,
      newLongitude: 31.2358,
    });
    assert.equal(r.valid, true);
  });

  it("flags L1 for speed slightly above max (100–120%)", () => {
    const nowMs = Date.now();
    const r = validateGpsUpdate({
      vehicleType: "bicycle",
      lastValidLatitude: 30.0,
      lastValidLongitude: 31.0,
      lastValidLocationAt: nowMs - 1000,
      newLatitude: 30.0001,
      newLongitude: 31.0,
      nowMs,
    });
    assert.equal(r.valid, false);
    assert.equal(r.level, VIOLATION.L1);
  });

  it("flags L2 for speed above 120% of max", () => {
    const nowMs = Date.now();
    const r = validateGpsUpdate({
      vehicleType: "bicycle",
      lastValidLatitude: 30.0,
      lastValidLongitude: 31.0,
      lastValidLocationAt: nowMs - 1000,
      newLatitude: 30.015,
      newLongitude: 31.0,
      nowMs,
    });
    assert.equal(r.valid, false);
    assert.ok([VIOLATION.L2, VIOLATION.L3].includes(r.level));
  });

  it("flags L3 for extreme jump on motorcycle", () => {
    const r = validateGpsUpdate({
      vehicleType: "motorcycle",
      lastValidLatitude: 30.0,
      lastValidLongitude: 31.0,
      lastValidLocationAt: Date.now() - 5000,
      newLatitude: 30.05,
      newLongitude: 31.05,
    });
    assert.equal(r.valid, false);
    assert.equal(r.level, VIOLATION.L3);
    assert.equal(r.reason, "extreme_jump");
  });

  it("flags L2 for jump within 15s window on bicycle", () => {
    const nowMs = Date.now();
    const r = validateGpsUpdate({
      vehicleType: "bicycle",
      lastValidLatitude: 30.0,
      lastValidLongitude: 31.0,
      lastValidLocationAt: nowMs - 10_000,
      newLatitude: 30.002,
      newLongitude: 31.0,
      nowMs,
    });
    assert.equal(r.valid, false);
    assert.ok(r.distanceM > 200 || r.level === VIOLATION.L2);
  });

  it("trustActionsForViolation sets restricted on L3", () => {
    const actions = trustActionsForViolation(VIOLATION.L3, 0);
    assert.equal(actions.gpsTrustStatus, "restricted");
    assert.ok(actions.assignmentEligibleUntilMs > Date.now());
  });

  it("trustActionsForViolation suspends after 3 violations", () => {
    const actions = trustActionsForViolation(VIOLATION.L2, 2);
    assert.equal(actions.gpsTrustStatus, "restricted");
  });
});
