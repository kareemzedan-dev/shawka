const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated } = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");

/**
 * حذف حساب العميل الحالي (Auth + Firestore + صور الإثبات).
 * مطلوب لمتطلبات Google Play / App Store لحسابات المستخدمين الدائمة.
 */
const deleteMyAccount = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const uid = auth.uid;
    const db = getFirestore();

    await checkRateLimit(db, `deleteMyAccount:${uid}`, 5, 60 * 60 * 1000);

    const tokenRole = auth.token.role || "customer";
    if (tokenRole === "admin" || tokenRole === "delivery") {
      throw new HttpsError(
        "failed-precondition",
        "لا يمكن حذف هذا النوع من الحسابات من التطبيق.",
      );
    }

    const userRef = db.collection("users").doc(uid);
    const snap = await userRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "الحساب غير موجود.");
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
        "لا يمكن حذف حساب إداري بهذه الطريقة.",
      );
    }

    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `customers/${uid}/` });
    } catch (e) {
      console.warn("deleteMyAccount storage cleanup", e?.message || e);
    }

    // حذف بيانات المستخدم الفرعية الشائعة قبل المستند الرئيسي.
    const subcollections = ["saved_addresses", "favorites", "notifications"];
    for (const name of subcollections) {
      try {
        const col = userRef.collection(name);
        const docs = await col.limit(200).get();
        if (!docs.empty) {
          const batch = db.batch();
          for (const doc of docs.docs) {
            batch.delete(doc.ref);
          }
          await batch.commit();
        }
      } catch (e) {
        console.warn(`deleteMyAccount subcollection ${name}`, e?.message || e);
      }
    }

    await userRef.delete();

    try {
      await getAuth().deleteUser(uid);
    } catch (e) {
      console.warn("deleteMyAccount auth delete", e?.message || e);
      throw new HttpsError(
        "internal",
        "تعذّر حذف الحساب بالكامل — تواصل مع الدعم.",
      );
    }

    await writeAuditLog(db, {
      type: "customer_self_account_deleted",
      actorUid: uid,
      actorRole: "customer",
      targetType: "user",
      targetId: uid,
      details: {
        phone: data.phone || "",
        name: data.name || "",
        email: data.email || "",
        selfDeleted: true,
      },
    });

    return { ok: true, deleted: true };
  },
);

module.exports = { deleteMyAccount };
