const { describe, it, before, beforeEach } = require("node:test");
const assert = require("node:assert/strict");
const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const { HttpsError } = require("firebase-functions/v2/https");

const { initAdmin, clearFirestore } = require("./setup");
const {
  seedDriver,
  seedOrder,
  startAssignmentPipeline,
  acceptOrderOffer,
  rejectOrderOffer,
  timeoutAndReassign,
  getOrder,
  getDriver,
  generateOperationId,
  DRIVER_TOKEN,
  CUSTOMER_TOKEN,
  ADMIN_TOKEN,
  STORE_LAT,
  STORE_LNG,
} = require("./helpers");

const { executeAdvanceDeliveryPhase } = require("../../driver/advanceDeliveryPhase");
const { executeCancelOrder } = require("../../assignment/cancelOrder");
const {
  executeAdminForceReleaseActiveOrder,
} = require("../../driver/adminForceReleaseActiveOrder");
const { processDriverLocationWrite } = require("../../driver/onDriverLocationWrite");
const { acceptOffer } = require("../../assignment/offerManager");

describe("Firebase Emulator E2E — Assignment Engine", () => {
  /** @type {import('firebase-admin/firestore').Firestore} */
  let db;

  before(() => {
    db = initAdmin();
  });

  beforeEach(async () => {
    await clearFirestore(db);
  });

  it("1. Order Ready → Assignment → Accept → Delivered", async () => {
    const driverId = "driver-happy";
    const orderId = "order-happy";

    await seedDriver(db, driverId, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedOrder(db, orderId);

    await startAssignmentPipeline(db, orderId);

    const offered = await getOrder(db, orderId);
    assert.equal(offered.deliveryPhase, "offered");
    assert.equal(offered.offeredDriverId, driverId);

    await acceptOrderOffer(db, orderId, driverId, generateOperationId());

    const accepted = await getOrder(db, orderId);
    assert.equal(accepted.deliveryPhase, "accepted");
    assert.equal(accepted.deliveryId, driverId);

    const lockedDriver = await getDriver(db, driverId);
    assert.equal(lockedDriver.activeOrderId, orderId);

    await executeAdvanceDeliveryPhase(db, {
      orderId,
      uid: driverId,
      token: DRIVER_TOKEN,
      phase: "picked_up",
    });
    await executeAdvanceDeliveryPhase(db, {
      orderId,
      uid: driverId,
      token: DRIVER_TOKEN,
      phase: "in_transit",
    });
    await executeAdvanceDeliveryPhase(db, {
      orderId,
      uid: driverId,
      token: DRIVER_TOKEN,
      phase: "delivered",
    });

    const delivered = await getOrder(db, orderId);
    assert.equal(delivered.status, "delivered");
    assert.equal(delivered.deliveryPhase, "delivered");
    assert.equal(delivered.assignmentStatus, "completed");

    const releasedDriver = await getDriver(db, driverId);
    assert.ok(!releasedDriver.activeOrderId);
  });

  it("2. Order Ready → Reject → Reassign → Accept", async () => {
    const driverA = "driver-reject-a";
    const driverB = "driver-reject-b";
    const orderId = "order-reject";

    await seedDriver(db, driverA, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedDriver(db, driverB, { lat: STORE_LAT + 0.002, lng: STORE_LNG + 0.002 });
    await seedOrder(db, orderId);

    await startAssignmentPipeline(db, orderId);

    const firstOffer = await getOrder(db, orderId);
    assert.equal(firstOffer.offeredDriverId, driverA);

    await rejectOrderOffer(db, orderId, driverA);

    const secondOffer = await getOrder(db, orderId);
    assert.equal(secondOffer.deliveryPhase, "offered");
    assert.equal(secondOffer.offeredDriverId, driverB);
    assert.ok(secondOffer.rejectedDriverIds.includes(driverA));

    await acceptOrderOffer(db, orderId, driverB, generateOperationId());

    const accepted = await getOrder(db, orderId);
    assert.equal(accepted.deliveryId, driverB);
    assert.equal(accepted.deliveryPhase, "accepted");
  });

  it("3. Timeout → Reassign", async () => {
    const driverA = "driver-timeout-a";
    const driverB = "driver-timeout-b";
    const orderId = "order-timeout";

    await seedDriver(db, driverA, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedDriver(db, driverB, { lat: STORE_LAT + 0.003, lng: STORE_LNG + 0.003 });
    await seedOrder(db, orderId);

    await startAssignmentPipeline(db, orderId);

    const offered = await getOrder(db, orderId);
    assert.equal(offered.offeredDriverId, driverA);

    await db.collection("orders").doc(orderId).update({
      deliveryAcceptDeadline: Timestamp.fromMillis(Date.now() - 60_000),
    });

    const timeoutResult = await timeoutAndReassign(db, orderId);
    assert.equal(timeoutResult.ok, true);

    const reassigned = await getOrder(db, orderId);
    assert.equal(reassigned.deliveryPhase, "offered");
    assert.equal(reassigned.offeredDriverId, driverB);
    assert.ok(reassigned.rejectedDriverIds.includes(driverA));
  });

  it("4. Active Order Lock blocks accept", async () => {
    const driverId = "driver-locked";
    const orderId = "order-lock-test";
    const otherOrderId = "other-active-order";

    await seedDriver(db, driverId, {
      lat: STORE_LAT + 0.001,
      lng: STORE_LNG + 0.001,
    });
    await seedOrder(db, orderId);
    await startAssignmentPipeline(db, orderId);

    const offered = await getOrder(db, orderId);
    assert.equal(offered.offeredDriverId, driverId);

    await db.collection("users").doc(driverId).update({
      activeOrderId: otherOrderId,
    });

    await assert.rejects(
      () =>
        acceptOrderOffer(db, orderId, driverId, generateOperationId()),
      (err) => {
        assert.ok(err instanceof HttpsError);
        assert.match(String(err.message), /ACTIVE_ORDER_LOCK/);
        return true;
      },
    );
  });

  it("5. Double Accept Race Condition — one winner only", async () => {
    const driverId = "driver-race";
    const orderId = "order-race";

    await seedDriver(db, driverId, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedOrder(db, orderId);
    await startAssignmentPipeline(db, orderId);

    const results = await Promise.allSettled([
      acceptOffer(db, {
        orderId,
        driverId,
        operationId: generateOperationId(),
      }),
      acceptOffer(db, {
        orderId,
        driverId,
        operationId: generateOperationId(),
      }),
    ]);

    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");

    assert.equal(fulfilled.length, 1, "exactly one accept should succeed");
    assert.equal(rejected.length, 1, "exactly one accept should fail");

    const order = await getOrder(db, orderId);
    assert.equal(order.deliveryId, driverId);
    assert.equal(order.deliveryPhase, "accepted");

    const driver = await getDriver(db, driverId);
    assert.equal(driver.activeOrderId, orderId);
  });

  it("6. GPS Violation L2 — rollback + violation counter", async () => {
    const driverId = "driver-gps-l2";
    const baseLat = STORE_LAT;
    const baseLng = STORE_LNG;
    const lastValidAt = Timestamp.fromMillis(Date.now() - 10_000);

    await seedDriver(db, driverId, {
      lat: baseLat,
      lng: baseLng,
      lastValidLatitude: baseLat,
      lastValidLongitude: baseLng,
      lastValidLocationAt: lastValidAt,
      gpsViolationCount24h: 0,
    });

    const before = await getDriver(db, driverId);
    const badLat = baseLat + 0.0054;
    const badLng = baseLng;

    await db.collection("users").doc(driverId).update({
      latitude: badLat,
      longitude: badLng,
      locationUpdatedAt: FieldValue.serverTimestamp(),
    });

    const afterWrite = await getDriver(db, driverId);
    const result = await processDriverLocationWrite(db, {
      userId: driverId,
      before,
      after: afterWrite,
    });

    assert.equal(result.valid, false);
    assert.equal(result.level, "L2");

    const driver = await getDriver(db, driverId);
    assert.equal(driver.gpsViolationCount24h, 1);
    assert.equal(driver.latitude, baseLat);
    assert.equal(driver.longitude, baseLng);
  });

  it("7. GPS Violation L3 — restricted trust status", async () => {
    const driverId = "driver-gps-l3";
    const baseLat = STORE_LAT;
    const baseLng = STORE_LNG;
    const lastValidAt = Timestamp.fromMillis(Date.now() - 5_000);

    await seedDriver(db, driverId, {
      lat: baseLat,
      lng: baseLng,
      lastValidLatitude: baseLat,
      lastValidLongitude: baseLng,
      lastValidLocationAt: lastValidAt,
      gpsViolationCount24h: 0,
    });

    const before = await getDriver(db, driverId);
    const teleportLat = baseLat + 0.025;
    const teleportLng = baseLng + 0.025;

    await db.collection("users").doc(driverId).update({
      latitude: teleportLat,
      longitude: teleportLng,
      locationUpdatedAt: FieldValue.serverTimestamp(),
    });

    const afterWrite = await getDriver(db, driverId);
    const result = await processDriverLocationWrite(db, {
      userId: driverId,
      before,
      after: afterWrite,
    });

    assert.equal(result.valid, false);
    assert.equal(result.level, "L3");

    const driver = await getDriver(db, driverId);
    assert.equal(driver.gpsTrustStatus, "restricted");
    assert.ok(driver.assignmentEligibleUntil);
    assert.equal(driver.latitude, baseLat);
    assert.equal(driver.longitude, baseLng);
  });

  it("8. Cancel During Offer", async () => {
    const driverId = "driver-cancel-offer";
    const orderId = "order-cancel-offer";

    await seedDriver(db, driverId, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedOrder(db, orderId);
    await startAssignmentPipeline(db, orderId);

    const offered = await getOrder(db, orderId);
    assert.equal(offered.deliveryPhase, "offered");

    await executeCancelOrder(db, {
      orderId,
      uid: "customer-1",
      token: CUSTOMER_TOKEN,
      reason: "customer_changed_mind",
    });

    const cancelled = await getOrder(db, orderId);
    assert.equal(cancelled.status, "cancelled");
    assert.equal(cancelled.deliveryPhase, "cancelled");
    assert.equal(cancelled.assignmentStatus, "cancelled");
    assert.ok(!cancelled.offeredDriverId);

    const driver = await getDriver(db, driverId);
    assert.ok(!driver.activeOrderId);
  });

  it("9. Cancel After Accept — releases activeOrderId", async () => {
    const driverId = "driver-cancel-accept";
    const orderId = "order-cancel-accept";

    await seedDriver(db, driverId, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedOrder(db, orderId);
    await startAssignmentPipeline(db, orderId);
    await acceptOrderOffer(db, orderId, driverId, generateOperationId());

    const locked = await getDriver(db, driverId);
    assert.equal(locked.activeOrderId, orderId);

    await executeCancelOrder(db, {
      orderId,
      uid: "customer-1",
      token: CUSTOMER_TOKEN,
      reason: "customer_cancelled_after_accept",
    });

    const cancelled = await getOrder(db, orderId);
    assert.equal(cancelled.status, "cancelled");

    const released = await getDriver(db, driverId);
    assert.ok(!released.activeOrderId);
  });

  it("10. Admin Force Release Active Order", async () => {
    const driverId = "driver-force-release";
    const orderId = "order-force-release";
    const adminId = "admin-ops";

    await seedDriver(db, driverId, { lat: STORE_LAT + 0.001, lng: STORE_LNG + 0.001 });
    await seedOrder(db, orderId);
    await startAssignmentPipeline(db, orderId);
    await acceptOrderOffer(db, orderId, driverId, generateOperationId());

    const locked = await getDriver(db, driverId);
    assert.equal(locked.activeOrderId, orderId);

    await executeAdminForceReleaseActiveOrder(db, {
      driverId,
      orderId,
      reason: "stuck_lock_recovery",
      actorUid: adminId,
      actorRole: "admin",
    });

    const released = await getDriver(db, driverId);
    assert.ok(!released.activeOrderId);

    const order = await getOrder(db, orderId);
    assert.ok(!order.deliveryId);
    assert.equal(order.deliveryPhase, "unassigned");
    assert.equal(order.assignmentStatus, "searching");
  });
});
