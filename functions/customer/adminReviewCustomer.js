const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated } = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");

function canReviewCustomers(token) {
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
 * موافقة أو رفض طلب تسجيل عميل (مع حذف الحساب عند الرفض).
 * data: { customerId: string, decision: 'approved'|'rejected', note?: string }
 */
const adminReviewCustomer = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    if (!canReviewCustomers(auth.token)) {
      throw new HttpsError("permission-denied", "صلاحية مراجعة العملاء مرفوضة.");
    }

    const db = getFirestore();
    await checkRateLimit(db, `adminReviewCustomer:${auth.uid}`, 40, 60 * 1000);

    const customerId =
      typeof request.data?.customerId === "string"
        ? request.data.customerId.trim()
        : "";
    const decision =
      typeof request.data?.decision === "string" ? request.data.decision : "";
    const note =
      typeof request.data?.note === "string"
        ? request.data.note.slice(0, 500)
        : "";

    if (!customerId) {
      throw new HttpsError("invalid-argument", "customerId مطلوب.");
    }
    if (!["approved", "rejected"].includes(decision)) {
      throw new HttpsError("invalid-argument", "decision غير صالح.");
    }

    const userRef = db.collection("users").doc(customerId);
    const snap = await userRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "العميل غير موجود.");
    }

    const data = snap.data() || {};
    if ((data.role || "customer") !== "customer" || data.isGuest === true) {
      throw new HttpsError("failed-precondition", "هذا الحساب ليس طلب عميل.");
    }

    const status = data.customerApprovalStatus || "";
    if (status === decision) {
      throw new HttpsError("already-exists", "ALREADY_REVIEWED");
    }
    if (status === "incomplete" || data.signupComplete === false) {
      throw new HttpsError(
        "failed-precondition",
        "طلب التسجيل غير مكتمل — يجب إكمال الإثبات والعنوان أولاً.",
      );
    }

    if (decision === "approved") {
      const proof = (data.proofImageUrl || "").trim();
      if (!proof) {
        throw new HttpsError(
          "failed-precondition",
          "لا توجد صورة إثبات للموافقة.",
        );
      }

      await userRef.update({
        customerApprovalStatus: "approved",
        signupComplete: true,
        customerApprovalNote: note || FieldValue.delete(),
        customerApprovedAt: FieldValue.serverTimestamp(),
        customerRejectedAt: FieldValue.delete(),
        isActive: true,
        isGuest: false,
        updatedAt: FieldValue.serverTimestamp(),
      });

      await writeAuditLog(db, {
        type: "customer_registration_approved",
        actorUid: auth.uid,
        actorRole: auth.token.staffRole || "admin",
        targetType: "user",
        targetId: customerId,
        details: {
          decision,
          note,
          phone: data.phone || "",
          activityTypeName: data.activityTypeName || "",
        },
      });

      return { ok: true, customerId, decision };
    }

    // rejected → delete Auth + Firestore + Storage proof
    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `customers/${customerId}/` });
    } catch (e) {
      console.warn("adminReviewCustomer storage cleanup", e?.message || e);
    }

    await userRef.delete();

    try {
      await getAuth().deleteUser(customerId);
    } catch (e) {
      console.warn("adminReviewCustomer auth delete", e?.message || e);
    }

    await writeAuditLog(db, {
      type: "customer_registration_rejected",
      actorUid: auth.uid,
      actorRole: auth.token.staffRole || "admin",
      targetType: "user",
      targetId: customerId,
      details: {
        decision,
        note,
        phone: data.phone || "",
        activityTypeName: data.activityTypeName || "",
        deleted: true,
      },
    });

    return { ok: true, customerId, decision, deleted: true };
  },
);

module.exports = { adminReviewCustomer };
