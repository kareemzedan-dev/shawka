/** Admin-managed order lifecycle (no driver app required). */

const STORE_MANAGED_STATUSES = new Set([
  "pending",
  "preparing",
  "readyForPickup",
  "onTheWay",
  "outForDelivery",
  "delivered",
]);

const ADMIN_TRANSITIONS = {
  pending: new Set([
    "preparing",
    "readyForPickup",
    "onTheWay",
    "outForDelivery",
    "delivered",
    "cancelled",
  ]),
  preparing: new Set([
    "readyForPickup",
    "onTheWay",
    "outForDelivery",
    "delivered",
    "cancelled",
  ]),
  readyForPickup: new Set([
    "onTheWay",
    "outForDelivery",
    "delivered",
    "cancelled",
  ]),
  onTheWay: new Set(["delivered", "cancelled"]),
  outForDelivery: new Set(["delivered", "cancelled"]),
  delivered: new Set([]),
  cancelled: new Set([]),
};

function canAdminTransition(fromStatus, toStatus) {
  if (!fromStatus || !toStatus || fromStatus === toStatus) return true;
  const allowed = ADMIN_TRANSITIONS[fromStatus];
  return allowed ? allowed.has(toStatus) : false;
}

function isReadyForDriverAssignment(status) {
  return status === "readyForPickup";
}

module.exports = {
  STORE_MANAGED_STATUSES,
  ADMIN_TRANSITIONS,
  canAdminTransition,
  isReadyForDriverAssignment,
};
