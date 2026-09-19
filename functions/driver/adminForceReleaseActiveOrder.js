const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  assertCanManageOrders,
} = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");
const { clearActiveOrderLock } = require("../assignment/offerManager");

async function executeAdminForceReleaseActiveOrder(
  db,
  { driverId, orderId, reason, actorUid, actorRole = "admin" },
) {
  if (!driverId) {
    throw new HttpsError("invalid-argument", "driverId مطلوب.");
  }

  const driverRef = db.collection("users").doc(driverId);
  const driverSnap = await driverRef.get();
  if (!driverSnap.exists) {
    throw new HttpsError("not-found", "المندوب غير موجود.");
  }

  const activeOrderId = driverSnap.data().activeOrderId;
  if (orderId && activeOrderId && activeOrderId !== orderId) {
    throw new HttpsError("failed-precondition", "ORDER_LOCK_MISMATCH");
  }

  await clearActiveOrderLock(db, {
    driverId,
    orderId: orderId || activeOrderId,
    actorUid,
    reason: reason || "admin_force_release",
  });

  if (orderId || activeOrderId) {
    const oid = orderId || activeOrderId;
    const orderRef = db.collection("orders").doc(oid);
    const orderSnap = await orderRef.get();
    if (orderSnap.exists && orderSnap.data().deliveryId === driverId) {
      await orderRef.update({
        deliveryPhase: "unassigned",
        assignmentStatus: "searching",
        deliveryId: FieldValue.delete(),
        deliveryName: FieldValue.delete(),
        deliveryPhone: FieldValue.delete(),
        deliveryVehicleType: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  await writeAuditLog(db, {
    type: "admin_force_release_active_order",
    actorUid,
    actorRole,
    targetType: "user",
    targetId: driverId,
    details: { orderId: orderId || activeOrderId, reason },
    severity: "warning",
  });

  return { ok: true, driverId, orderId: orderId || activeOrderId };
}

const adminForceReleaseActiveOrder = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    assertCanManageOrders(auth.token);

    const db = getFirestore();
    await checkRateLimit(db, `forceRelease:${auth.uid}`, 20, 60 * 1000);

    const driverId =
      typeof request.data?.driverId === "string" ? request.data.driverId : "";
    const orderId =
      typeof request.data?.orderId === "string" ? request.data.orderId : "";
    const reason =
      typeof request.data?.reason === "string"
        ? request.data.reason.slice(0, 300)
        : "admin_force_release";

    return executeAdminForceReleaseActiveOrder(db, {
      driverId,
      orderId,
      reason,
      actorUid: auth.uid,
      actorRole: auth.token.staffRole || "admin",
    });
  },
);

module.exports = { adminForceReleaseActiveOrder, executeAdminForceReleaseActiveOrder };
