const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeRating,
  isDelivered,
  assertRatingRequest,
} = require("../driverRating");

test("normalizeRating accepts integers and rejects invalid values", () => {
  assert.equal(normalizeRating(5), 5);
  assert.equal(normalizeRating(4.7), 5);
  assert.equal(normalizeRating("3"), 3);
  assert.equal(normalizeRating(0), null);
  assert.equal(normalizeRating(6), null);
  assert.equal(normalizeRating("x"), null);
});

test("isDelivered accepts status or deliveryPhase delivered", () => {
  assert.equal(isDelivered({ status: "delivered" }), true);
  assert.equal(isDelivered({ deliveryPhase: "delivered" }), true);
  assert.equal(isDelivered({ deliveryDeliveredAt: new Date() }), true);
  assert.equal(isDelivered({ status: "outForDelivery" }), false);
});

test("assertRatingRequest validates ownership and delivery state", () => {
  const order = {
    customerId: "cust-1",
    status: "delivered",
    deliveryId: "driver-1",
    driverRating: null,
  };
  assert.equal(assertRatingRequest(order, "cust-1"), "driver-1");

  assert.throws(
    () => assertRatingRequest(order, "other"),
    (err) => err.code === "permission-denied",
  );
  assert.throws(
    () =>
      assertRatingRequest(
        { ...order, status: "onTheWay", deliveryPhase: "in_transit" },
        "cust-1",
      ),
    (err) => err.code === "failed-precondition",
  );
});
