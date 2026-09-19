const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const { setUserClaims } = require("../authClaims");

const CREATABLE_STAFF_ROLES = new Set([
  "storeAssistant",
  "contentEditor",
  "support",
  "manager",
]);

function canCreateStaff(token) {
  if ((token.role || "customer") !== "admin") return false;
  const sr = token.staffRole || "admin";
  return sr === "superAdmin" || sr === "admin";
}

/**
 * إنشاء حساب موظف للوحة التحكم (بريد + كلمة مرور).
 * data: { name, email, password, phone?, staffRole? }
 * الافتراضي: storeAssistant (مساعد تشغيل).
 */
const adminCreateStaffUser = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
    }
    if (!canCreateStaff(request.auth.token)) {
      throw new HttpsError(
        "permission-denied",
        "صلاحية إنشاء حساب مساعد مرفوضة — Admin فقط.",
      );
    }

    const db = getFirestore();
    await checkRateLimit(
      db,
      `createStaff:${request.auth.uid}`,
      20,
      60 * 1000,
    );

    const name =
      typeof request.data?.name === "string" ? request.data.name.trim() : "";
    const email =
      typeof request.data?.email === "string"
        ? request.data.email.trim().toLowerCase()
        : "";
    const password =
      typeof request.data?.password === "string" ? request.data.password : "";
    const phone =
      typeof request.data?.phone === "string" ? request.data.phone.trim() : "";
    const staffRole =
      typeof request.data?.staffRole === "string"
        ? request.data.staffRole.trim()
        : "storeAssistant";

    if (name.length < 2 || name.length > 80) {
      throw new HttpsError("invalid-argument", "أدخل اسماً صالحاً.");
    }
    if (!email.includes("@") || email.length < 5) {
      throw new HttpsError("invalid-argument", "البريد غير صالح.");
    }
    if (password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "كلمة المرور يجب أن تكون 6 أحرف على الأقل.",
      );
    }
    if (!CREATABLE_STAFF_ROLES.has(staffRole)) {
      throw new HttpsError("invalid-argument", "نوع الحساب غير مسموح.");
    }

    let userRecord;
    try {
      userRecord = await getAuth().createUser({
        email,
        password,
        displayName: name,
        emailVerified: true,
      });
    } catch (e) {
      if (e.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "البريد مستخدم مسبقاً.");
      }
      throw new HttpsError("internal", String(e.message || e));
    }

    const uid = userRecord.uid;
    const profile = {
      name,
      email,
      phone,
      role: "admin",
      staffRole,
      isGuest: false,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
      createdByAdmin: request.auth.uid,
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection("users").doc(uid).set(profile);
    await setUserClaims(uid, profile);

    return {
      ok: true,
      uid,
      email,
      staffRole,
      name,
    };
  },
);

module.exports = { adminCreateStaffUser };
