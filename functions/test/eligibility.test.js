const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const {
  hasActiveOrderLock,
  isPresenceOnline,
  isGpsEligible,
  isAssignmentEligible,
} = require("../assignment/eligibility");
const { getConfig } = require("../shared/config");

describe("eligibility", () => {
  const config = getConfig();
  const now = Date.now();

  const baseDriver = {
    isDriverOnline: true,
    driverApprovalStatus: "approved",
    isActive: true,
    heartbeatAt: { toMillis: () => now - 30_000 },
    locationUpdatedAt: { toMillis: () => now - 60_000 },
    latitude: 30.04,
    longitude: 31.23,
    gpsTrustStatus: "trusted",
  };

  it("hasActiveOrderLock detects non-empty lock", () => {
    assert.equal(hasActiveOrderLock({ activeOrderId: "order-1" }), true);
    assert.equal(hasActiveOrderLock({ activeOrderId: "" }), false);
    assert.equal(hasActiveOrderLock({}), false);
  });

  it("isPresenceOnline requires fresh heartbeat and location", () => {
    assert.equal(isPresenceOnline(baseDriver, now, config), true);
    assert.equal(
      isPresenceOnline(
        {
          ...baseDriver,
          heartbeatAt: { toMillis: () => now - 500_000 },
        },
        now,
        config,
      ),
      true,
    );
    assert.equal(
      isPresenceOnline(
        {
          ...baseDriver,
          isDriverOnline: false,
          heartbeatAt: { toMillis: () => now - 500_000 },
        },
        now,
        config,
      ),
      false,
    );
  });

  it("isGpsEligible ignores stale assignmentEligibleUntil when trusted", () => {
    assert.equal(
      isGpsEligible(
        {
          gpsTrustStatus: "trusted",
          assignmentEligibleUntil: { toMillis: () => now + 3_600_000 },
        },
        now,
        config,
      ),
      true,
    );
  });

  it("isAssignmentEligible fails when offline toggle off", () => {
    const r = isAssignmentEligible(
      { ...baseDriver, isDriverOnline: false },
      now,
      config,
    );
    assert.equal(r.eligible, false);
    assert.equal(r.reason, "presence");
  });

  it("isGpsEligible rejects suspended trust", () => {
    assert.equal(
      isGpsEligible({ gpsTrustStatus: "suspended" }, now, config),
      false,
    );
    assert.equal(isGpsEligible({ gpsTrustStatus: "trusted" }, now, config), true);
  });

  it("isAssignmentEligible fails when activeOrderId set", () => {
    const r = isAssignmentEligible(
      { ...baseDriver, activeOrderId: "busy-order" },
      now,
      config,
    );
    assert.equal(r.eligible, false);
    assert.equal(r.reason, "active_order_lock");
  });

  it("isAssignmentEligible passes for idle online driver", () => {
    const r = isAssignmentEligible(baseDriver, now, config);
    assert.equal(r.eligible, true);
    assert.ok(r.coords);
  });

  it("isAssignmentEligible passes for legacy admin driver without approval field", () => {
    const r = isAssignmentEligible(
      {
        ...baseDriver,
        driverApprovalStatus: undefined,
        isActive: true,
      },
      now,
      config,
      { governorate: "القاهرة", storeLat: 30.04, storeLng: 31.23 },
    );
    assert.equal(r.eligible, true);
  });

  it("isAssignmentEligible uses store coords when driver online same governorate", () => {
    const r = isAssignmentEligible(
      {
        ...baseDriver,
        latitude: undefined,
        longitude: undefined,
        lastValidLatitude: undefined,
        lastValidLongitude: undefined,
        governorate: "القاهرة",
      },
      now,
      config,
      {
        governorate: "القاهرة",
        storeLat: 30.05,
        storeLng: 31.24,
      },
    );
    assert.equal(r.eligible, true);
    assert.equal(r.coords.lat, 30.05);
  });
});
