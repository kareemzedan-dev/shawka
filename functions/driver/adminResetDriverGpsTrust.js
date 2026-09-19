const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  assertCanManageDeliveryUsers,
  resolveRole,
} = require("../shared/permissions");
const { writeAuditLog } = require("../shared/audit");

function extractCoords(data) {
  if (!data) return null;
  if (typeof data.latitude === "number" && typeof data.longitude === "number") {
    return { lat: data.latitude, lng: data.longitude };
  }
  const loc = data.location;
  if (loc && typeof loc.latitude === "number" && typeof loc.longitude === "number") {
    return { lat: loc.latitude, lng: loc.longitude };
  }
  return null;
}

/**
 * Admin-only immediate GPS trust reset for stuck drivers (suspended/restricted).
 * Establishes a clean lastValid baseline and a short grace window so the next
 * location ticks cannot instantly re-suspend the driver.
 */
const adminResetDriverGpsTrust = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    assertCanManageDeliveryUsers(auth.token);

    const db = getFirestore();
    await checkRateLimit(db, `adminResetDriverGpsTrust:${auth.uid}`, 40, 60 * 1000);

    const driverId =
      typeof request.data?.driverId === "string" ? request.data.driverId.trim() : "";
    if (!driverId) {
      throw new HttpsError("invalid-argument", "driverId مطلوب.");
    }

    const driverRef = db.collection("users").doc(driverId);
    const snap = await driverRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "المندوب غير موجود.");
    }

    const before = snap.data() || {};
    if (resolveRole(before) !== "delivery") {
      throw new HttpsError("not-found", "المندوب غير موجود.");
    }

    const coords = extractCoords(before);
    const update = {
      gpsTrustStatus: "trusted",
      gpsViolationCount24h: 0,
      assignmentEligibleUntil: FieldValue.delete(),
      locationRejectedAt: FieldValue.delete(),
      isDriverOnline: false,
      gpsAdminResetAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    // Keep a stable baseline from the last known point so the next tick
    // is not treated as an extreme jump against a deleted/null baseline race.
    if (coords) {
      update.lastValidLatitude = coords.lat;
      update.lastValidLongitude = coords.lng;
      update.lastValidLocationAt = FieldValue.serverTimestamp();
    } else {
      update.lastValidLatitude = FieldValue.delete();
      update.lastValidLongitude = FieldValue.delete();
      update.lastValidLocationAt = FieldValue.delete();
    }

    await driverRef.update(update);

    await writeAuditLog(db, {
      type: "gps_trust_reset",
      actorUid: auth.uid,
      actorRole: auth.token.staffRole || "admin",
      targetType: "user",
      targetId: driverId,
      details: {
        previousTrust: before.gpsTrustStatus || "trusted",
        previousViolations: before.gpsViolationCount24h ?? 0,
        baselineRestored: Boolean(coords),
      },
    });

    return { ok: true, driverId, gpsTrustStatus: "trusted" };
  },
);

module.exports = { adminResetDriverGpsTrust };
