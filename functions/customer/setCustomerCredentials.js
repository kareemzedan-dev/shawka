const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated } = require("../shared/permissions");

function normalizeEgyptianE164(raw) {
  const digits = String(raw || "")
    .replace(/[^\d+]/g, "")
    .trim();
  if (!digits) return null;

  let national;
  if (digits.startsWith("+20")) national = digits.slice(3);
  else if (digits.startsWith("0020")) national = digits.slice(4);
  else if (digits.startsWith("20") && digits.length >= 12) national = digits.slice(2);
  else if (digits.startsWith("0")) national = digits.slice(1);
  else national = digits;

  if (!/^1\d{9}$/.test(national)) return null;
  return `+20${national}`;
}

/** بريد داخلي ثابت من رقم الموبايل لتسجيل الدخول بالباسورد. */
function phoneToAuthEmail(e164) {
  const digits = String(e164 || "").replace(/\D/g, "");
  return `${digits}@phone.shawka.app`;
}

/**
 * بعد التحقق من OTP: ربط الاسم + كلمة المرور بحساب الموبايل.
 * data: { name: string, password: string }
 */
const setCustomerCredentials = onCall(
  {
    region: FUNCTIONS_REGION,
    memory: "256MiB",
  },
  async (request) => {
    const authCtx = assertAuthenticated(request);
    const db = getFirestore();
    await checkRateLimit(
      db,
      `setCustomerCredentials:${authCtx.uid}`,
      8,
      15 * 60 * 1000,
    );

    const name =
      typeof request.data?.name === "string" ? request.data.name.trim() : "";
    const password =
      typeof request.data?.password === "string" ? request.data.password : "";

    if (name.length < 2 || name.length > 80) {
      throw new HttpsError("invalid-argument", "أدخل اسماً صالحاً");
    }
    if (password.length < 6 || password.length > 128) {
      throw new HttpsError(
        "invalid-argument",
        "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
      );
    }

    const auth = getAuth();
    let userRecord;
    try {
      userRecord = await auth.getUser(authCtx.uid);
    } catch (_) {
      throw new HttpsError("not-found", "الحساب غير موجود");
    }

    const phone = userRecord.phoneNumber || "";
    if (!normalizeEgyptianE164(phone)) {
      throw new HttpsError(
        "failed-precondition",
        "تحقق من رقم الموبايل أولاً عبر رمز OTP",
      );
    }

    const email = phoneToAuthEmail(phone);

    try {
      await auth.updateUser(authCtx.uid, {
        email,
        password,
        displayName: name,
        emailVerified: true,
        phoneNumber: phone,
      });
    } catch (e) {
      if (e?.code === "auth/email-already-exists") {
        // نفس البريد لنفس الرقم غالباً — حدّث الباسورد فقط.
        try {
          await auth.updateUser(authCtx.uid, {
            password,
            displayName: name,
            emailVerified: true,
          });
        } catch (inner) {
          throw new HttpsError(
            "already-exists",
            "هذا الرقم مرتبط بحساب آخر",
          );
        }
      } else {
        console.error("setCustomerCredentials updateUser", e);
        throw new HttpsError("internal", "تعذّر حفظ كلمة المرور");
      }
    }

    const userRef = db.collection("users").doc(authCtx.uid);
    const existingSnap = await userRef.get();
    const existingData = existingSnap.exists ? existingSnap.data() || {} : {};
    const existingStatus = String(
      existingData.customerApprovalStatus || "",
    ).trim();
    // لا تخفض حالة طلب مكتمل أو معتمد عند إعادة حفظ كلمة المرور.
    const preserveAccessStatus =
      existingStatus === "approved" || existingStatus === "pending";

    await userRef.set(
      {
        name,
        phone,
        email,
        hasPassword: true,
        role: "customer",
        isGuest: false,
        updatedAt: FieldValue.serverTimestamp(),
        ...(preserveAccessStatus
          ? {}
          : {
              signupComplete: false,
              customerApprovalStatus: "incomplete",
              isActive: false,
            }),
      },
      { merge: true },
    );

    return { ok: true, email, phone };
  },
);

module.exports = {
  setCustomerCredentials,
  phoneToAuthEmail,
  normalizeEgyptianE164,
};
