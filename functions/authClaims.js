const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("./rateLimit");

const VALID_STAFF_ROLES = new Set([
  "superAdmin",
  "admin",
  "manager",
  "support",
  "contentEditor",
  "storeManager",
  "storeAssistant",
]);

function resolveRole(data) {
  if (!data) return "customer";
  return data.role || data.rule || "customer";
}

function normalizeStoreIds(raw) {
  if (!Array.isArray(raw)) return [];
  const ids = [
    ...new Set(
      raw
        .map((id) => (typeof id === "string" ? id.trim() : ""))
        .filter((id) => id.length >= 4 && id.length <= 128),
    ),
  ];
  return ids.slice(0, 20);
}

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

async function setUserClaims(uid, data) {
  const role = resolveRole(data);
  const claims = { role };

  if (role === "admin") {
    const staffRole = data.staffRole || "admin";
    claims.staffRole = VALID_STAFF_ROLES.has(staffRole) ? staffRole : "admin";
    const storeIds = normalizeStoreIds(data.managedStoreIds);
    if (claims.staffRole === "storeManager" && storeIds.length > 0) {
      claims.managedStoreIds = storeIds;
    }
  }

  await getAuth().setCustomUserClaims(uid, claims);
  return claims;
}

function assertSuperOrAdmin(token) {
  const staffRole = token.staffRole || "admin";
  if (staffRole !== "superAdmin" && staffRole !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "صلاحية مرفوضة — Super Admin أو Admin فقط.",
    );
  }
}

/**
 * يزامن Custom Claims (JWT) مع مستند users/{uid} تلقائياً.
 */
const syncAuthClaimsOnUserWrite = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    await setUserClaims(event.params.userId, after.data());
  },
);

/**
 * يحدّث JWT claims للمستخدم الحالي من Firestore — يُستدعى بعد تسجيل الدخول.
 */
const refreshAuthClaims = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  await checkRateLimit(db, `refreshClaims:${uid}`, 15, 60 * 1000);

  const snap = await db.collection("users").doc(uid).get();
  const profile = snap.exists ? snap.data() : { role: "customer" };

  const claims = await setUserClaims(uid, profile);
  return { ok: true, claims, profilePending: !snap.exists };
});

/**
 * تغيير staffRole عبر السيرفر — Rate Limited + JWT RBAC.
 * عند storeManager يجب تمرير managedStoreIds (متجر واحد على الأقل).
 */
const adminSetStaffRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }

  assertSuperOrAdmin(request.auth.token);

  const db = getFirestore();
  await checkRateLimit(db, `adminOps:${request.auth.uid}`, 60, 60 * 1000);

  const targetUid = request.data?.targetUid;
  const staffRole = request.data?.staffRole;
  const managedStoreIds = normalizeStoreIds(request.data?.managedStoreIds);

  if (typeof targetUid !== "string" || targetUid.length < 8) {
    throw new HttpsError("invalid-argument", "targetUid غير صالح.");
  }
  if (!VALID_STAFF_ROLES.has(staffRole)) {
    throw new HttpsError("invalid-argument", "staffRole غير صالح.");
  }

  const callerStaff = request.auth.token.staffRole || "admin";
  if (staffRole === "superAdmin" && callerStaff !== "superAdmin") {
    throw new HttpsError(
      "permission-denied",
      "فقط Super Admin يمكنه تعيين Super Admin.",
    );
  }

  if (staffRole === "storeManager" && managedStoreIds.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "يجب اختيار متجر واحد على الأقل لصاحب المتجر.",
    );
  }

  const targetSnap = await db.collection("users").doc(targetUid).get();
  if (!targetSnap.exists || resolveRole(targetSnap.data()) !== "admin") {
    throw new HttpsError("failed-precondition", "المستخدم ليس موظف admin.");
  }

  if (
    targetSnap.data().staffRole === "superAdmin" &&
    targetUid === request.auth.uid
  ) {
    throw new HttpsError(
      "permission-denied",
      "لا يمكنك تغيير دور Super Admin الخاص بك.",
    );
  }

  if (staffRole === "storeManager") {
    await assertStoresExist(db, managedStoreIds);
    await db.collection("users").doc(targetUid).update({
      staffRole,
      managedStoreIds,
    });
  } else {
    await db.collection("users").doc(targetUid).update({
      staffRole,
      managedStoreIds: FieldValue.delete(),
    });
  }

  return { ok: true, targetUid, staffRole, managedStoreIds };
});

/**
 * ترقية حساب عميل إلى صاحب متجر مربوط بمتجر محدد.
 * يقبل targetUid أو targetPhone (موبايل العميل) أو targetEmail (للتوافق).
 */
const adminAssignStoreOwner = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }

  assertSuperOrAdmin(request.auth.token);

  const db = getFirestore();
  await checkRateLimit(db, `adminOps:${request.auth.uid}`, 60, 60 * 1000);

  const managedStoreIds = normalizeStoreIds(request.data?.managedStoreIds);
  if (managedStoreIds.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "يجب اختيار متجر واحد على الأقل.",
    );
  }

  await assertStoresExist(db, managedStoreIds);

  let targetUid =
    typeof request.data?.targetUid === "string"
      ? request.data.targetUid.trim()
      : "";

  const targetPhoneRaw =
    typeof request.data?.targetPhone === "string"
      ? request.data.targetPhone.trim()
      : "";
  const targetEmail =
    typeof request.data?.targetEmail === "string"
      ? request.data.targetEmail.trim().toLowerCase()
      : "";

  const targetPhone = normalizeEgyptianE164(targetPhoneRaw);

  if (!targetUid && targetPhone) {
    const byPhone = await db
      .collection("users")
      .where("phone", "==", targetPhone)
      .limit(1)
      .get();
    if (!byPhone.empty) {
      targetUid = byPhone.docs[0].id;
    } else {
      try {
        const userRecord = await getAuth().getUserByPhoneNumber(targetPhone);
        targetUid = userRecord.uid;
      } catch (_) {
        throw new HttpsError(
          "not-found",
          "لا يوجد حساب بهذا الرقم — يجب أن يسجّل العميل أولاً في التطبيق برقم الموبايل.",
        );
      }
    }
  }

  if (!targetUid && targetEmail) {
    try {
      const userRecord = await getAuth().getUserByEmail(targetEmail);
      targetUid = userRecord.uid;
    } catch (_) {
      throw new HttpsError(
        "not-found",
        "لا يوجد حساب بهذا البريد — يجب أن يسجّل صاحب المتجر أولاً في التطبيق.",
      );
    }
  }

  if (!targetUid || targetUid.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "أدخل رقم موبايل العميل المسجّل في التطبيق.",
    );
  }

  const ref = db.collection("users").doc(targetUid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError(
      "not-found",
      "مستند المستخدم غير موجود في Firestore.",
    );
  }

  const data = snap.data() || {};
  const currentRole = resolveRole(data);
  if (currentRole === "delivery") {
    throw new HttpsError(
      "failed-precondition",
      "لا يمكن تحويل حساب دليفري إلى صاحب متجر.",
    );
  }

  if (data.staffRole === "superAdmin") {
    throw new HttpsError(
      "permission-denied",
      "لا يمكن تعديل حساب Super Admin.",
    );
  }

  await ref.set(
    {
      role: "admin",
      staffRole: "storeManager",
      managedStoreIds,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return {
    ok: true,
    targetUid,
    phone: data.phone || targetPhone || "",
    email: data.email || targetEmail || "",
    staffRole: "storeManager",
    managedStoreIds,
  };
});

/**
 * إزالة صاحب متجر — يرجع الحساب لعميل عادي ويمسح ربط المتاجر.
 * data: { targetUid: string }
 */
const adminRemoveStoreOwner = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول.");
  }

  assertSuperOrAdmin(request.auth.token);

  const db = getFirestore();
  await checkRateLimit(db, `adminOps:${request.auth.uid}`, 60, 60 * 1000);

  const targetUid =
    typeof request.data?.targetUid === "string"
      ? request.data.targetUid.trim()
      : "";

  if (!targetUid || targetUid.length < 8) {
    throw new HttpsError("invalid-argument", "targetUid غير صالح.");
  }

  if (targetUid === request.auth.uid) {
    throw new HttpsError(
      "failed-precondition",
      "لا يمكنك إزالة صلاحياتك وأنت مسجّل الدخول.",
    );
  }

  const ref = db.collection("users").doc(targetUid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "الحساب غير موجود.");
  }

  const data = snap.data() || {};
  const staffRole = data.staffRole || "";
  if (staffRole === "superAdmin") {
    throw new HttpsError(
      "permission-denied",
      "لا يمكن إزالة Super Admin بهذا الإجراء.",
    );
  }

  if (staffRole !== "storeManager" && staffRole !== "storeAssistant") {
    throw new HttpsError(
      "failed-precondition",
      "هذا الحساب ليس صاحب متجر أو مساعد تشغيل.",
    );
  }

  // ارجع لعميل عادي مع الإبقاء على بيانات التسجيل/الموافقة.
  await ref.set(
    {
      role: "customer",
      staffRole: FieldValue.delete(),
      managedStoreIds: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // تأكيد مسح claims فوراً (بالإضافة لمزامنة onWrite).
  await setUserClaims(targetUid, {
    role: "customer",
    ...(data.phone ? { phone: data.phone } : {}),
  });

  return {
    ok: true,
    targetUid,
    phone: data.phone || "",
    name: data.name || "",
  };
});

async function assertStoresExist(db, storeIds) {
  const snaps = await db.getAll(
    ...storeIds.map((id) => db.collection("stores").doc(id)),
  );
  for (const snap of snaps) {
    if (!snap.exists) {
      throw new HttpsError("not-found", `المتجر غير موجود: ${snap.id}`);
    }
  }
}

module.exports = {
  syncAuthClaimsOnUserWrite,
  refreshAuthClaims,
  adminSetStaffRole,
  adminAssignStoreOwner,
  adminRemoveStoreOwner,
  setUserClaims,
};
