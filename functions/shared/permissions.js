const { HttpsError } = require("firebase-functions/v2/https");
const { isDriverApproved } = require("../assignment/eligibility");

function resolveRole(data) {
  if (!data) return "customer";
  return data.role || data.rule || "customer";
}

function staffRole(token) {
  return token.staffRole || "admin";
}

function canManageDeliveryUsers(token) {
  if ((token.role || "customer") !== "admin") return false;
  const sr = staffRole(token);
  return sr === "superAdmin" || sr === "admin" || sr === "manager" || sr === "support";
}

function canManageOrders(token) {
  if ((token.role || "customer") !== "admin") return false;
  const sr = staffRole(token);
  return (
    sr === "superAdmin" ||
    sr === "admin" ||
    sr === "manager" ||
    sr === "support" ||
    sr === "storeManager" ||
    sr === "storeAssistant"
  );
}

function assertAuthenticated(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }
  return request.auth;
}

function assertDeliveryDriver(token, userData) {
  if ((token.role || "customer") !== "delivery") {
    throw new HttpsError("permission-denied", "صلاحية مندوب فقط.");
  }
  const data = userData || {};
  // Align with assignment eligibility — legacy drivers may omit driverApprovalStatus.
  if (!isDriverApproved(data)) {
    throw new HttpsError("failed-precondition", "المندوب غير معتمد.");
  }
  if (data.isActive === false) {
    throw new HttpsError("failed-precondition", "حساب المندوب غير نشط.");
  }
}

function assertCanManageOrders(token) {
  if (!canManageOrders(token)) {
    throw new HttpsError("permission-denied", "صلاحية إدارة الطلبات مرفوضة.");
  }
}

function assertCanManageDeliveryUsers(token) {
  if (!canManageDeliveryUsers(token)) {
    throw new HttpsError("permission-denied", "صلاحية إدارة المناديب مرفوضة.");
  }
}

function isCustomerOwner(order, uid) {
  return order.customerId === uid;
}

module.exports = {
  resolveRole,
  staffRole,
  canManageDeliveryUsers,
  canManageOrders,
  assertAuthenticated,
  assertDeliveryDriver,
  assertCanManageOrders,
  assertCanManageDeliveryUsers,
  isCustomerOwner,
};
