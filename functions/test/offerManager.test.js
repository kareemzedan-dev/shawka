const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { checkAcceptEligibility } = require("../assignment/offerManager");

describe("offerManager", () => {
  const futureDeadline = {
    toMillis: () => Date.now() + 60_000,
  };

  const eligibleDriver = {
    isDriverOnline: true,
    driverApprovalStatus: "approved",
    isActive: true,
    heartbeatAt: { toMillis: () => Date.now() - 30_000 },
    locationUpdatedAt: { toMillis: () => Date.now() - 60_000 },
    latitude: 30.04,
    longitude: 31.23,
    gpsTrustStatus: "trusted",
  };

  const offeredOrder = {
    offeredDriverId: "driver1",
    deliveryPhase: "offered",
    deliveryAcceptDeadline: futureDeadline,
  };

  it("blocks accept when activeOrderId is set", () => {
    const driver = {
      ...eligibleDriver,
      activeOrderId: "other-order-123",
    };
    const reason = checkAcceptEligibility(offeredOrder, driver, "driver1");
    assert.equal(reason, "ACTIVE_ORDER_LOCK");
  });

  it("allows accept when activeOrderId is empty", () => {
    const driver = { ...eligibleDriver, activeOrderId: null };
    const reason = checkAcceptEligibility(offeredOrder, driver, "driver1");
    assert.equal(reason, null);
  });

  it("blocks accept when not the offered driver", () => {
    const reason = checkAcceptEligibility(
      offeredOrder,
      eligibleDriver,
      "other-driver",
    );
    assert.equal(reason, "NOT_OFFERED_DRIVER");
  });

  it("blocks accept after deadline", () => {
    const pastOrder = {
      ...offeredOrder,
      deliveryAcceptDeadline: { toMillis: () => Date.now() - 1000 },
    };
    const reason = checkAcceptEligibility(
      pastOrder,
      eligibleDriver,
      "driver1",
      Date.now(),
    );
    assert.equal(reason, "DEADLINE_EXCEEDED");
  });

  it("allows accept when driver has no GPS coords", () => {
    const driver = {
      isDriverOnline: true,
      driverApprovalStatus: "approved",
      isActive: true,
      activeOrderId: null,
    };
    const reason = checkAcceptEligibility(offeredOrder, driver, "driver1");
    assert.equal(reason, null);
  });

  it("allows accept for legacy drivers without approval status", () => {
    const driver = {
      isDriverOnline: true,
      isActive: true,
      activeOrderId: null,
      latitude: 30.04,
      longitude: 31.23,
    };
    const reason = checkAcceptEligibility(offeredOrder, driver, "driver1");
    assert.equal(reason, null);
  });
});
