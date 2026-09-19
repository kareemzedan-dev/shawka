const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated } = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");

function canDeleteCustomers(token) {
  if ((token.role || "customer") !== "admin") return false;
  const sr = token.staffRole || "admin";
  return (
    sr === "superAdmin" ||
    sr === "admin" ||
    sr === "manager" ||
    sr === "support"
  );
}

/**
 * حذف حساب عميل نهائياً (Auth + Firestore + صور الإثبات).
 * data: { customerId: string, note?: string }
 */
const adminDeleteCustomer = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    if (!canDeleteCustomers(auth.token)) {
      throw new HttpsError("permission-denied", "صلاحية حذف العملاء مرفوضة.");
    }

    const db = getFirestore();
    await checkRateLimit(db, `adminDeleteCustomer:${auth.uid}`, 30, 60 * 1000);

    const customerId =
      typeof request.data?.customerId === "string"
        ? request.data.customerId.trim()
        : "";
    const note =
      typeof request.data?.note === "string"
        ? request.data.note.slice(0, 500)
        : "";

    if (!customerId) {
      throw new HttpsError("invalid-argument", "customerId مطلوب.");
    }
    if (customerId === auth.uid) {
      throw new HttpsError(
        "failed-precondition",
        "لا يمكنك حذف حسابك وأنت مسجّل الدخول.",
      );
    }

    const userRef = db.collection("users").doc(customerId);
    const snap = await userRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "العميل غير موجود.");
    }

    const data = snap.data() || {};
    const role = data.role || data.rule || "customer";
    if (role !== "customer") {
      throw new HttpsError(
        "failed-precondition",
        "يمكن حذف حسابات العملاء فقط من هنا.",
      );
    }
    if (data.staffRole === "superAdmin" || data.staffRole === "admin") {
      throw new HttpsError(
        "permission-denied",
        "لا يمكن حذف حساب إداري من قائمة العملاء.",
      );
    }

    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `customers/${customerId}/` });
    } catch (e) {
      console.warn("adminDeleteCustomer storage cleanup", e?.message || e);
    }

    await userRef.delete();

    try {
      await getAuth().deleteUser(customerId);
    } catch (e) {
      console.warn("adminDeleteCustomer auth delete", e?.message || e);
    }

    await writeAuditLog(db, {
      type: "customer_account_deleted",
      actorUid: auth.uid,
      actorRole: auth.token.staffRole || "admin",
      targetType: "user",
      targetId: customerId,
      details: {
        note,
        phone: data.phone || "",
        name: data.name || "",
        email: data.email || "",
        wasGuest: data.isGuest === true,
        deleted: true,
      },
    });

    return { ok: true, customerId, deleted: true };
  },
);

module.exports = { adminDeleteCustomer };
