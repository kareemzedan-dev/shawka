const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { setUserClaims } = require("../authClaims");
const { FUNCTIONS_REGION } = require("../shared/region");
const { assertAuthenticated } = require("../shared/permissions");
const { VALID_VEHICLE_TYPES } = require("../shared/config");

const driverRegister = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const db = getFirestore();
    const uid = auth.uid;

    await checkRateLimit(db, `driverRegister:${uid}`, 5, 60 * 60 * 1000);

    const existing = await db.collection("users").doc(uid).get();
    if (existing.exists && existing.data().role === "delivery") {
      throw new HttpsError("already-exists", "ALREADY_REGISTERED");
    }

    const name =
      typeof request.data?.name === "string" ? request.data.name.trim() : "";
    const phone =
      typeof request.data?.phone === "string" ? request.data.phone.trim() : "";
    const governorate =
      typeof request.data?.governorate === "string"
        ? request.data.governorate.trim()
        : "";
    const nationalId =
      typeof request.data?.nationalId === "string"
        ? request.data.nationalId.trim()
        : "";
    const vehicleType =
      typeof request.data?.vehicleType === "string"
        ? request.data.vehicleType.trim()
        : "";
    const vehicleModel =
      typeof request.data?.vehicleModel === "string"
        ? request.data.vehicleModel.trim()
        : "";
    const vehiclePlate =
      typeof request.data?.vehiclePlate === "string"
        ? request.data.vehiclePlate.trim()
        : "";
    const email =
      typeof request.data?.email === "string"
        ? request.data.email.trim()
        : "";

    if (name.length < 2) {
      throw new HttpsError("invalid-argument", "الاسم مطلوب.");
    }
    if (phone.length < 8) {
      throw new HttpsError("invalid-argument", "رقم الهاتف مطلوب.");
    }
    if (!governorate) {
      throw new HttpsError("invalid-argument", "المحافظة مطلوبة.");
    }
    if (!VALID_VEHICLE_TYPES.has(vehicleType)) {
      throw new HttpsError("invalid-argument", "نوع المركبة غير صالح.");
    }

    const govSnap = await db
      .collection("governorates")
      .where("name", "==", governorate)
      .limit(1)
      .get();
    if (govSnap.empty) {
      const govDoc = await db.collection("governorates").doc(governorate).get();
      if (!govDoc.exists) {
        throw new HttpsError("invalid-argument", "INVALID_GOVERNORATE");
      }
    }

    const profile = {
      name,
      phone,
      governorate,
      nationalId,
      vehicleType,
      vehicleModel,
      vehiclePlate,
      role: "delivery",
      driverApprovalStatus: "pending",
      isActive: true,
      isGuest: false,
      gpsTrustStatus: "trusted",
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    };

    if (email) profile.email = email;

    await db.collection("users").doc(uid).set(profile, { merge: true });
    await setUserClaims(uid, { role: "delivery" });

    if (email && request.data?.password) {
      try {
        await getAuth().updateUser(uid, { email, displayName: name });
      } catch (e) {
        // Non-fatal if auth email update fails
      }
    }

    return { ok: true, uid, event: "registration_submitted" };
  },
);

module.exports = { driverRegister };
