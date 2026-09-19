const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  assertCanManageDeliveryUsers,
} = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");

const REQUIRED_DOCS = ["license", "id_front", "id_back"];

const adminReviewDriver = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    assertCanManageDeliveryUsers(auth.token);

    const db = getFirestore();
    await checkRateLimit(db, `adminReviewDriver:${auth.uid}`, 40, 60 * 1000);

    const driverId =
      typeof request.data?.driverId === "string" ? request.data.driverId : "";
    const decision =
      typeof request.data?.decision === "string" ? request.data.decision : "";
    const note =
      typeof request.data?.note === "string"
        ? request.data.note.slice(0, 500)
        : "";

    if (!driverId) {
      throw new HttpsError("invalid-argument", "driverId مطلوب.");
    }
    if (!["approved", "rejected", "suspended"].includes(decision)) {
      throw new HttpsError("invalid-argument", "decision غير صالح.");
    }

    const driverRef = db.collection("users").doc(driverId);
    const snap = await driverRef.get();
    if (!snap.exists || snap.data().role !== "delivery") {
      throw new HttpsError("not-found", "المندوب غير موجود.");
    }

    const driver = snap.data();
    const currentStatus = driver.driverApprovalStatus || "pending";

    if (decision !== "suspended" && currentStatus === decision) {
      throw new HttpsError("already-exists", "ALREADY_REVIEWED");
    }

    if (decision === "approved") {
      const docs = driver.documents || {};
      const hasDocs = REQUIRED_DOCS.every((k) => docs[k]);
      if (!hasDocs) {
        throw new HttpsError("failed-precondition", "INCOMPLETE_REGISTRATION");
      }
    }

    const update = {
      driverApprovalStatus: decision === "suspended" ? "suspended" : decision,
      driverApprovalNote: note || FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (decision === "approved") {
      update.driverApprovedAt = FieldValue.serverTimestamp();
      update.isActive = true;
      update.driverRejectedAt = FieldValue.delete();
    } else if (decision === "rejected") {
      update.driverRejectedAt = FieldValue.serverTimestamp();
      update.isActive = false;
    } else if (decision === "suspended") {
      update.isActive = false;
      update.isDriverOnline = false;
    }

    await driverRef.update(update);

    await writeAuditLog(db, {
      type: decision === "approved" ? "registration_approved" : "registration_rejected",
      actorUid: auth.uid,
      actorRole: auth.token.staffRole || "admin",
      targetType: "user",
      targetId: driverId,
      details: { decision, note },
    });

    return {
      ok: true,
      driverId,
      decision,
      event:
        decision === "approved"
          ? "registration_approved"
          : "registration_rejected",
    };
  },
);

module.exports = { adminReviewDriver };
