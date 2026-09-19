const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const { encodeGeohash } = require("../../shared/geohash");
const { getConfig } = require("../../shared/config");
const { handleOrderReadyForPickup } = require("../../assignment/onOrderReadyForPickup");
const { runAssignOrderRound } = require("../../assignment/assignOrderRoundCore");
const { drainQueue } = require("../../jobQueue");
const {
  acceptOffer,
  rejectOffer,
  timeoutOfferForOrder,
  generateOperationId,
} = require("../../assignment/offerManager");

const STORE_LAT = 30.0444;
const STORE_LNG = 31.2357;
const GOVERNORATE = "Cairo";

const TEST_CONFIG = getConfig({
  driver_assignment_accept_seconds: 45,
  driver_assignment_max_rounds: 5,
});

const DRIVER_TOKEN = { role: "delivery" };
const CUSTOMER_TOKEN = { role: "customer" };
const ADMIN_TOKEN = { role: "admin", staffRole: "admin" };

function freshPresenceTimestamps(offsetMs = 0) {
  const ts = Timestamp.fromMillis(Date.now() - offsetMs);
  return {
    heartbeatAt: ts,
    locationUpdatedAt: ts,
    lastValidLocationAt: ts,
  };
}

async function seedDriver(db, id, { lat, lng, ...overrides } = {}) {
  const latitude = lat ?? STORE_LAT + 0.001;
  const longitude = lng ?? STORE_LNG + 0.001;
  const presence = freshPresenceTimestamps(30_000);
  const geohash = encodeGeohash(latitude, longitude);

  await db.collection("users").doc(id).set({
    role: "delivery",
    name: `Driver ${id}`,
    isDriverOnline: true,
    driverApprovalStatus: "approved",
    isActive: true,
    governorate: GOVERNORATE,
    latitude,
    longitude,
    geohash,
    vehicleType: "motorcycle",
    gpsTrustStatus: "trusted",
    gpsViolationCount24h: 0,
    ...presence,
    lastValidLatitude: latitude,
    lastValidLongitude: longitude,
    ...overrides,
  });

  return id;
}

async function seedOrder(db, id, overrides = {}) {
  await db.collection("orders").doc(id).set({
    status: "preparing",
    customerId: "customer-1",
    governorate: GOVERNORATE,
    storeLat: STORE_LAT,
    storeLng: STORE_LNG,
    rejectedDriverIds: [],
    ...overrides,
  });
  return id;
}

async function drainPendingJobs(db, maxPasses = 12) {
  let total = 0;
  for (let i = 0; i < maxPasses; i += 1) {
    const processed = await drainQueue(db);
    if (processed === 0) break;
    total += processed;
  }
  return total;
}

/**
 * Simulates status → readyForPickup + onOrderReadyForPickup trigger + job drain.
 */
async function startAssignmentPipeline(db, orderId) {
  const orderRef = db.collection("orders").doc(orderId);
  const beforeSnap = await orderRef.get();
  const before = beforeSnap.data();

  await orderRef.update({ status: "readyForPickup", updatedAt: FieldValue.serverTimestamp() });
  const afterSnap = await orderRef.get();

  await handleOrderReadyForPickup(db, orderId, before, afterSnap.data());
  await drainPendingJobs(db);

  return orderRef.get();
}

async function assignNextRound(db, orderId, round) {
  await runAssignOrderRound(db, { orderId, round, config: TEST_CONFIG });
}

async function acceptOrderOffer(db, orderId, driverId, operationId) {
  return acceptOffer(db, {
    orderId,
    driverId,
    operationId: operationId || generateOperationId(),
    config: TEST_CONFIG,
  });
}

async function rejectOrderOffer(db, orderId, driverId, reason = "rejected") {
  const result = await rejectOffer(db, {
    orderId,
    driverId,
    reason,
    config: TEST_CONFIG,
  });
  await drainPendingJobs(db);
  return result;
}

async function timeoutAndReassign(db, orderId) {
  const result = await timeoutOfferForOrder(db, orderId, TEST_CONFIG);
  await drainPendingJobs(db);
  return result;
}

async function getOrder(db, orderId) {
  const snap = await db.collection("orders").doc(orderId).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

async function getDriver(db, driverId) {
  const snap = await db.collection("users").doc(driverId).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

module.exports = {
  STORE_LAT,
  STORE_LNG,
  GOVERNORATE,
  TEST_CONFIG,
  DRIVER_TOKEN,
  CUSTOMER_TOKEN,
  ADMIN_TOKEN,
  freshPresenceTimestamps,
  seedDriver,
  seedOrder,
  drainPendingJobs,
  startAssignmentPipeline,
  assignNextRound,
  acceptOrderOffer,
  rejectOrderOffer,
  timeoutAndReassign,
  getOrder,
  getDriver,
  generateOperationId,
};
