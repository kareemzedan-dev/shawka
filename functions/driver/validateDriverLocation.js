const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue, GeoPoint } = require("firebase-admin/firestore");
const { FUNCTIONS_REGION } = require("../shared/region");
const { validateGpsUpdate } = require("../shared/gpsValidation");
const { encodeGeohash } = require("../shared/geohash");
const {
  assertAuthenticated,
  assertDeliveryDriver,
} = require("../shared/permissions");
const { checkRateLimit } = require("../rateLimit");

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts === "number") return ts;
  if (ts instanceof Date) return ts.getTime();
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (typeof ts.toDate === "function") return ts.toDate().getTime();
  return null;
}

/**
 * Callable GPS validation for go-online / recovery only — not per-tick GPS.
 * Per-tick validation runs via onDriverLocationWrite trigger.
 */
const validateDriverLocation = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const uid = auth.uid;
    const db = getFirestore();
    await checkRateLimit(db, `validateDriverLocation:${uid}`, 30, 60 * 1000);

    const latitude = request.data?.latitude;
    const longitude = request.data?.longitude;
    if (typeof latitude !== "number" || typeof longitude !== "number") {
      throw new HttpsError("invalid-argument", "إحداثيات غير صالحة");
    }

    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "المستخدم غير موجود");
    }

    const user = userSnap.data();
    assertDeliveryDriver(auth.token, user);

    const nowMs = Date.now();
    const trust = user.gpsTrustStatus || "trusted";
    const eligibleUntilMs = toMillis(user.assignmentEligibleUntil);
    const penaltyActive =
      eligibleUntilMs != null && eligibleUntilMs > nowMs;
    const isRecovery = trust === "restricted" || trust === "suspended";

    if (isRecovery && penaltyActive) {
      return {
        valid: false,
        reason: "penalty_active",
        violationLevel: null,
        gpsTrustStatus: trust,
        penaltyActive: true,
        penaltyEndsAtMs: eligibleUntilMs,
      };
    }

    // Go-online / recovery preflight only — never compare against stale lastValid.
    // Jump/speed checks run on onDriverLocationWrite for ongoing ticks.
    const validation = validateGpsUpdate({
      vehicleType: user.vehicleType || "motorcycle",
      lastValidLatitude: null,
      lastValidLongitude: null,
      lastValidLocationAt: null,
      newLatitude: latitude,
      newLongitude: longitude,
      nowMs,
    });

    if (!validation.valid) {
      return {
        valid: false,
        violationLevel: validation.level || null,
        reason: validation.reason || null,
        impliedSpeedKmh: validation.impliedSpeedKmh ?? null,
        gpsTrustStatus: trust,
        penaltyActive: false,
      };
    }

    const geohash = encodeGeohash(latitude, longitude);
    const recoveryUpdate = {
      lastValidLatitude: latitude,
      lastValidLongitude: longitude,
      lastValidLocationAt: FieldValue.serverTimestamp(),
      latitude,
      longitude,
      location: new GeoPoint(latitude, longitude),
      locationUpdatedAt: FieldValue.serverTimestamp(),
      geohash,
      geohashUpdatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (trust === "restricted" || trust === "suspended") {
      recoveryUpdate.gpsTrustStatus = "trusted";
      recoveryUpdate.assignmentEligibleUntil = FieldValue.delete();
      recoveryUpdate.gpsViolationCount24h = 0;
    }

    await userRef.update(recoveryUpdate);

    return {
      valid: true,
      recovered: trust !== "trusted",
      violationLevel: validation.level || null,
      reason: validation.reason || null,
      impliedSpeedKmh: validation.impliedSpeedKmh ?? null,
      gpsTrustStatus: "trusted",
      penaltyActive: false,
    };
  },
);

module.exports = { validateDriverLocation };
