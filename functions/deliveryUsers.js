const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("./rateLimit");
const { setUserClaims } = require("./authClaims");

function canManageDeliveryUsers(token) {
  const role = token.role || "customer";
  if (role !== "admin") return false;
  const staffRole = token.staffRole || "admin";
  return (
    staffRole === "superAdmin" ||
    staffRole === "admin" ||
    staffRole === "manager" ||
    staffRole === "support"
  );
}

/**
 * إنشاء حساب مندوب توصيل — Auth + Firestore + JWT claims.
 */
const adminCreateDeliveryUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }
  if (!canManageDeliveryUsers(request.auth.token)) {
    throw new HttpsError("permission-denied", "صلاحية إنشاء مندوب مرفوضة.");
  }

  const db = getFirestore();
  await checkRateLimit(db, `createDelivery:${request.auth.uid}`, 20, 60 * 1000);

  const email =
    typeof request.data?.email === "string" ? request.data.email.trim() : "";
  const password =
    typeof request.data?.password === "string" ? request.data.password : "";
  const name =
    typeof request.data?.name === "string" ? request.data.name.trim() : "";
  const phone =
    typeof request.data?.phone === "string" ? request.data.phone.trim() : "";
  const governorate =
    typeof request.data?.governorate === "string"
      ? request.data.governorate.trim()
      : "";

  if (!email.includes("@") || email.length < 5) {
    throw new HttpsError("invalid-argument", "البريد غير صالح.");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "كلمة المرور 6 أحرف على الأقل.");
  }
  if (name.length < 2) {
    throw new HttpsError("invalid-argument", "الاسم مطلوب.");
  }

  let userRecord;
  try {
    userRecord = await getAuth().createUser({
      email,
      password,
      displayName: name,
    });
  } catch (e) {
    if (e.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "البريد مستخدم مسبقاً.");
    }
    throw new HttpsError("internal", String(e.message || e));
  }

  const uid = userRecord.uid;
  await db.collection("users").doc(uid).set({
    name,
    email,
    phone,
    governorate,
    role: "delivery",
    driverApprovalStatus: "approved",
    isActive: true,
    isGuest: false,
    isDriverOnline: false,
    gpsTrustStatus: "trusted",
    gpsViolationCount24h: 0,
    createdAt: FieldValue.serverTimestamp(),
    createdByAdmin: request.auth.uid,
  });

  await setUserClaims(uid, { role: "delivery" });

  return { ok: true, uid };
});

module.exports = { adminCreateDeliveryUser };
