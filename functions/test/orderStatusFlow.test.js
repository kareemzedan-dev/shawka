const test = require("node:test");
const assert = require("node:assert/strict");
const {
  canAdminTransition,
  isReadyForDriverAssignment,
} = require("../shared/orderStatusFlow");

test("isReadyForDriverAssignment only when readyForPickup", () => {
  assert.equal(isReadyForDriverAssignment("readyForPickup"), true);
  assert.equal(isReadyForDriverAssignment("pending"), false);
  assert.equal(isReadyForDriverAssignment("preparing"), false);
});

test("canAdminTransition allows full admin-managed delivery flow", () => {
  assert.equal(canAdminTransition("pending", "preparing"), true);
  assert.equal(canAdminTransition("preparing", "readyForPickup"), true);
  assert.equal(canAdminTransition("readyForPickup", "cancelled"), true);
  assert.equal(canAdminTransition("readyForPickup", "onTheWay"), true);
  assert.equal(canAdminTransition("readyForPickup", "delivered"), true);
  assert.equal(canAdminTransition("onTheWay", "delivered"), true);
  assert.equal(canAdminTransition("outForDelivery", "delivered"), true);
  assert.equal(canAdminTransition("pending", "delivered"), true);
  assert.equal(canAdminTransition("delivered", "cancelled"), false);
});
