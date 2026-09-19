const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated, canManageDeliveryUsers } = require("../shared/permissions");
const { applyWalletSettlement } = require("../shared/driverWallet");

/**
 * Admin: record COD settlement deposit for a driver.
 */
const adminWalletSettlement = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    if (!canManageDeliveryUsers(auth.token)) {
      throw new HttpsError("permission-denied", "غير مصرح.");
    }

    const driverId =
      typeof request.data?.driverId === "string" ? request.data.driverId : "";
    const amount = request.data?.amount;
    const notes =
      typeof request.data?.notes === "string" ? request.data.notes.trim() : "";

    if (!driverId || driverId.length < 8) {
      throw new HttpsError("invalid-argument", "driverId مطلوب.");
    }
    if (typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "المبلغ غير صالح.");
    }

    const db = getFirestore();
    const driverSnap = await db.collection("users").doc(driverId).get();
    if (!driverSnap.exists || driverSnap.data()?.role !== "delivery") {
      throw new HttpsError("not-found", "المندوب غير موجود.");
    }

    const result = await applyWalletSettlement(db, {
      driverId,
      amount,
      notes,
      createdBy: auth.uid,
      source: "admin_panel",
      performedByRole: "staff",
    });

    return { ok: true, ...result };
  },
);

module.exports = { adminWalletSettlement };
