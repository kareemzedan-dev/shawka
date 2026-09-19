const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated } = require("../shared/permissions");

function phoneToAuthEmail(e164) {
  const digits = String(e164 || "").replace(/\D/g, "");
  return `${digits}@phone.shawka.app`;
}

/**
 * إكمال ملف العميل بعد OTP + صورة الإثبات.
 * data: { phone, activityTypeId, activityTypeName, proofImageUrl,
 *         proofImageThumbUrl, displayName, address }
 */
const completeCustomerProfile = onCall(
  { region: FUNCTIONS_REGION, memory: "256MiB" },
  async (request) => {
    const authCtx = assertAuthenticated(request);
    const db = getFirestore();
    await checkRateLimit(
      db,
      `completeCustomerProfile:${authCtx.uid}`,
      10,
      15 * 60 * 1000,
    );

    const d = request.data || {};
    const phone = String(d.phone || "").trim();
    const activityTypeId = String(d.activityTypeId || "").trim();
    const activityTypeName = String(d.activityTypeName || "").trim();
    const proofImageUrl = String(d.proofImageUrl || "").trim();
    const proofImageThumbUrl = String(d.proofImageThumbUrl || "").trim();
    const displayName = String(d.displayName || "").trim();
    const address = String(d.address || "").trim();

    if (!proofImageUrl || proofImageUrl.length < 8) {
      throw new HttpsError("invalid-argument", "صورة الإثبات مطلوبة");
    }
    if (address.length < 10) {
      throw new HttpsError(
        "invalid-argument",
        "أدخل العنوان بالتفصيل (10 أحرف على الأقل)",
      );
    }
    if (!activityTypeId) {
      throw new HttpsError("invalid-argument", "اختر نوع النشاط");
    }

    const ref = db.collection("users").doc(authCtx.uid);
    const existing = await ref.get();
    const existingData = existing.exists ? existing.data() || {} : {};
    const existingStatus = String(
      existingData.customerApprovalStatus || "",
    ).trim();
    const keepApproved = existingStatus === "approved";

    const name =
      displayName ||
      (existingData.name || "").trim() ||
      activityTypeName;

    const authEmail = phoneToAuthEmail(phone);

    const payload = {
      name,
      phone,
      activityTypeId,
      activityTypeName,
      proofImageUrl,
      proofImageThumbUrl,
      address,
      customerApprovalStatus: keepApproved ? "approved" : "pending",
      signupComplete: true,
      isGuest: false,
      role: "customer",
      isActive: !!keepApproved,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (authEmail) payload.email = authEmail;
    if (!existing.exists) {
      payload.createdAt = FieldValue.serverTimestamp();
      payload.governorate = "";
    }

    await ref.set(payload, { merge: true });

    const doc = await ref.get();
    return { ok: true, userId: authCtx.uid, data: doc.data() };
  },
);

module.exports = { completeCustomerProfile };
