const crypto = require("crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { logger } = require("firebase-functions");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");

/** sms = إرسال عبر مزوّد | in_app = الرمز يُرجع للتطبيق بدون Google/reCAPTCHA */
function otpDeliveryMode() {
  return (process.env.OTP_DELIVERY_MODE || "in_app").trim().toLowerCase();
}

function smsWebhookUrl() {
  return (process.env.OTP_SMS_WEBHOOK_URL || "").trim();
}

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_LENGTH = 6;

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

function hashOtp(code, salt) {
  return crypto.createHash("sha256").update(`${salt}:${code}`).digest("hex");
}

function generateOtp() {
  const n = crypto.randomInt(0, 10 ** OTP_LENGTH);
  return String(n).padStart(OTP_LENGTH, "0");
}

function phoneDocId(e164) {
  return crypto.createHash("sha256").update(e164).digest("hex").slice(0, 40);
}

async function deliverSms({ e164, code }) {
  const webhook = smsWebhookUrl();
  if (!webhook) {
    throw new HttpsError(
      "failed-precondition",
      "مزوّد الرسائل غير مضبوط — راجع إعداد OTP_SMS_WEBHOOK_URL أو استخدم in_app.",
    );
  }

  const message = `رمز التحقق في شوّكة: ${code}`;
  const res = await fetch(webhook, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      to: e164,
      phone: e164,
      message,
      text: message,
      code,
    }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    logger.error("OTP SMS webhook failed", { status: res.status, body });
    throw new HttpsError("internal", "تعذّر إرسال رسالة التحقق");
  }
}

/**
 * إرسال OTP داخل التطبيق — بدون فتح Google/reCAPTCHA.
 * data: { phone: string }
 */
const sendCustomerPhoneOtp = onCall(
  {
    region: FUNCTIONS_REGION,
    memory: "256MiB",
    invoker: "public",
  },
  async (request) => {
    const db = getFirestore();
    const e164 = normalizeEgyptianE164(request.data?.phone);
    if (!e164) {
      throw new HttpsError(
        "invalid-argument",
        "رقم الموبايل غير صحيح — استخدم رقم مصري يبدأ بـ 01",
      );
    }

    const purpose =
      typeof request.data?.purpose === "string"
        ? request.data.purpose.trim().toLowerCase()
        : "signup";

    if (purpose === "signup") {
      const existing = await db
        .collection("users")
        .where("phone", "==", e164)
        .limit(1)
        .get();
      if (!existing.empty) {
        const data = existing.docs[0].data() || {};
        if (data.hasPassword === true) {
          throw new HttpsError(
            "already-exists",
            "هذا الرقم مسجّل بالفعل — سجّل الدخول بكلمة المرور",
          );
        }
      }
    }

    const ip =
      request.rawRequest?.ip ||
      request.rawRequest?.headers?.["x-forwarded-for"] ||
      "unknown";
    await checkRateLimit(db, `otpSend:phone:${e164}`, 4, 15 * 60 * 1000);
    await checkRateLimit(db, `otpSend:ip:${ip}`, 20, 15 * 60 * 1000);

    const code = generateOtp();
    const salt = crypto.randomBytes(16).toString("hex");
    const sessionId = crypto.randomBytes(24).toString("hex");
    const mode = otpDeliveryMode();
    const expiresAt = Timestamp.fromMillis(Date.now() + OTP_TTL_MS);

    await db
      .collection("phone_otps")
      .doc(phoneDocId(e164))
      .set({
        phone: e164,
        sessionId,
        codeHash: hashOtp(code, salt),
        salt,
        attempts: 0,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });

    if (mode === "sms") {
      await deliverSms({ e164, code });
      logger.info("OTP sent via SMS", { phone: e164.slice(0, 6) + "****" });
      return {
        ok: true,
        sessionId,
        expiresInSec: Math.floor(OTP_TTL_MS / 1000),
        delivery: "sms",
      };
    }

    // in_app: الرمز يُعرض داخل التطبيق — بدون أي تحقق روبوت خارجي.
    logger.info("OTP issued in_app", { phone: e164.slice(0, 6) + "****" });
    return {
      ok: true,
      sessionId,
      expiresInSec: Math.floor(OTP_TTL_MS / 1000),
      delivery: "in_app",
      code,
    };
  },
);

/**
 * التحقق من OTP وإصدار custom token لتسجيل الدخول.
 * data: { phone, sessionId, code }
 */
const verifyCustomerPhoneOtp = onCall(
  {
    region: FUNCTIONS_REGION,
    memory: "256MiB",
    invoker: "public",
  },
  async (request) => {
    const db = getFirestore();
    const e164 = normalizeEgyptianE164(request.data?.phone);
    const sessionId =
      typeof request.data?.sessionId === "string"
        ? request.data.sessionId.trim()
        : "";
    const code =
      typeof request.data?.code === "string"
        ? request.data.code.trim().replace(/\s+/g, "")
        : "";

    if (!e164) {
      throw new HttpsError("invalid-argument", "رقم الموبايل غير صحيح");
    }
    if (!sessionId || code.length !== OTP_LENGTH) {
      throw new HttpsError("invalid-argument", "رمز التحقق غير مكتمل");
    }

    await checkRateLimit(db, `otpVerify:phone:${e164}`, 12, 15 * 60 * 1000);

    const ref = db.collection("phone_otps").doc(phoneDocId(e164));
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "اطلب رمزاً جديداً أولاً");
    }

    const data = snap.data() || {};
    if (data.sessionId !== sessionId) {
      throw new HttpsError("failed-precondition", "جلسة التحقق غير صالحة");
    }

    const expiresAt = data.expiresAt?.toMillis?.() || 0;
    if (!expiresAt || Date.now() > expiresAt) {
      await ref.delete().catch(() => {});
      throw new HttpsError("deadline-exceeded", "انتهت صلاحية الرمز — اطلب رمزاً جديداً");
    }

    const attempts = Number(data.attempts || 0);
    if (attempts >= 5) {
      await ref.delete().catch(() => {});
      throw new HttpsError("resource-exhausted", "محاولات كثيرة — اطلب رمزاً جديداً");
    }

    const expected = hashOtp(code, data.salt || "");
    if (expected !== data.codeHash) {
      await ref.update({
        attempts: attempts + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("invalid-argument", "رمز التحقق غير صحيح");
    }

    await ref.delete().catch(() => {});

    const auth = getAuth();
    let uid;
    const currentUid =
      request.auth && request.auth.token?.firebase?.sign_in_provider === "anonymous"
        ? request.auth.uid
        : null;

    try {
      const existing = await auth.getUserByPhoneNumber(e164);
      uid = existing.uid;
    } catch (e) {
      if (e?.code !== "auth/user-not-found") {
        logger.error("getUserByPhoneNumber failed", e);
        throw new HttpsError("internal", "تعذّر التحقق من الحساب");
      }

      if (currentUid) {
        try {
          await auth.updateUser(currentUid, { phoneNumber: e164 });
          uid = currentUid;
        } catch (linkErr) {
          if (linkErr?.code === "auth/phone-number-already-exists") {
            const again = await auth.getUserByPhoneNumber(e164);
            uid = again.uid;
          } else {
            const created = await auth.createUser({ phoneNumber: e164 });
            uid = created.uid;
          }
        }
      } else {
        const created = await auth.createUser({ phoneNumber: e164 });
        uid = created.uid;
      }
    }

    let token;
    try {
      token = await auth.createCustomToken(uid, {
        phone: e164,
        phoneVerified: true,
      });
    } catch (tokenErr) {
      logger.error("createCustomToken failed", tokenErr);
      throw new HttpsError(
        "internal",
        "تعذّر إكمال تسجيل الدخول — صلاحيات الخادم ناقصة (signBlob).",
      );
    }

    return {
      ok: true,
      token,
      uid,
      phone: e164,
    };
  },
);

module.exports = {
  sendCustomerPhoneOtp,
  verifyCustomerPhoneOtp,
};
