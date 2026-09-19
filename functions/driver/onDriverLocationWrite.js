const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue, GeoPoint, Timestamp } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { encodeGeohash } = require("../shared/geohash");
const {
  validateGpsUpdate,
  trustActionsForViolation,
  VIOLATION,
} = require("../shared/gpsValidation");
const { writeAuditLog } = require("../shared/audit");

const LOCATION_FIELDS = new Set([
  "location",
  "latitude",
  "longitude",
  "locationUpdatedAt",
  "geohash",
  "geohashUpdatedAt",
]);

function locationFieldsChanged(before, after) {
  if (!before || !after) return false;
  for (const field of LOCATION_FIELDS) {
    if (JSON.stringify(before[field]) !== JSON.stringify(after[field])) {
      return true;
    }
  }
  return false;
}

function extractCoords(data) {
  if (typeof data.latitude === "number" && typeof data.longitude === "number") {
    return { lat: data.latitude, lng: data.longitude };
  }
  const loc = data.location;
  if (loc && typeof loc.latitude === "number") {
    return { lat: loc.latitude, lng: loc.longitude };
  }
  return null;
}

const STALE_BASELINE_MS = 30 * 60 * 1000;

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts === "number") return ts;
  if (ts instanceof Date) return ts.getTime();
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (typeof ts.toDate === "function") return ts.toDate().getTime();
  return null;
}

function resolveValidationBaseline(after, before, nowMs = Date.now()) {
  const lastLat = after.lastValidLatitude ?? before?.lastValidLatitude;
  const lastLng = after.lastValidLongitude ?? before?.lastValidLongitude;
  const lastAt = after.lastValidLocationAt ?? before?.lastValidLocationAt;
  const lastMs = toMillis(lastAt);

  if (lastMs == null || nowMs - lastMs > STALE_BASELINE_MS) {
    return {
      lastValidLatitude: null,
      lastValidLongitude: null,
      lastValidLocationAt: null,
    };
  }

  return {
    lastValidLatitude: lastLat,
    lastValidLongitude: lastLng,
    lastValidLocationAt: lastAt,
  };
}

const ADMIN_RESET_GRACE_MS = 5 * 60 * 1000;

async function acceptLocationAsValid(userRef, coords) {
  const geohash = encodeGeohash(coords.lat, coords.lng);
  await userRef.set(
    {
      lastValidLatitude: coords.lat,
      lastValidLongitude: coords.lng,
      lastValidLocationAt: FieldValue.serverTimestamp(),
      geohash,
      geohashUpdatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function processDriverLocationWrite(db, { userId, before, after }) {
  if (!after) return { skipped: true, reason: "deleted" };

  const role = after.role || after.rule || "";
  if (role !== "delivery") return { skipped: true, reason: "not_delivery" };
  if (!locationFieldsChanged(before, after)) {
    return { skipped: true, reason: "no_location_change" };
  }

  const coords = extractCoords(after);
  if (!coords) return { skipped: true, reason: "no_coords" };

  const userRef = db.collection("users").doc(userId);

  // After admin GPS restore, accept ticks for a short grace window and never
  // re-escalate trust from stale jump detection against pre-reset baselines.
  const resetAtMs = toMillis(after.gpsAdminResetAt);
  if (resetAtMs != null && Date.now() - resetAtMs < ADMIN_RESET_GRACE_MS) {
    await acceptLocationAsValid(userRef, coords);
    return { ok: true, valid: true, grace: true };
  }

  const baseline = resolveValidationBaseline(after, before);

  const validation = validateGpsUpdate({
    vehicleType: after.vehicleType || "motorcycle",
    lastValidLatitude: baseline.lastValidLatitude,
    lastValidLongitude: baseline.lastValidLongitude,
    lastValidLocationAt: baseline.lastValidLocationAt,
    newLatitude: coords.lat,
    newLongitude: coords.lng,
  });

  if (validation.valid) {
    await acceptLocationAsValid(userRef, coords);
    return { ok: true, valid: true };
  }

  if (validation.level === VIOLATION.L1) {
    const rollback = buildRollback(before, after);
    if (Object.keys(rollback).length > 0) {
      await userRef.update(rollback);
    }
    return { ok: true, valid: false, level: validation.level, rolledBack: true };
  }

  const count24h =
    typeof after.gpsViolationCount24h === "number"
      ? after.gpsViolationCount24h
      : typeof before?.gpsViolationCount24h === "number"
        ? before.gpsViolationCount24h
        : 0;

  const actions = trustActionsForViolation(validation.level, count24h);
  const rollback = buildRollback(before, after);
  const trustUpdate = {
    ...rollback,
    locationRejectedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (actions.incrementCounter) {
    trustUpdate.gpsViolationCount24h = FieldValue.increment(1);
  }
  if (actions.gpsTrustStatus) {
    trustUpdate.gpsTrustStatus = actions.gpsTrustStatus;
  }
  if (actions.assignmentEligibleUntilMs) {
    trustUpdate.assignmentEligibleUntil = Timestamp.fromMillis(
      actions.assignmentEligibleUntilMs,
    );
  }

  await userRef.update(trustUpdate);

  await writeAuditLog(db, {
    type: "gps_violation",
    actorUid: userId,
    actorRole: "delivery",
    targetType: "user",
    targetId: userId,
    details: {
      level: validation.level,
      reason: validation.reason,
      impliedSpeedKmh: validation.impliedSpeedKmh,
      distanceM: validation.distanceM,
    },
    severity: validation.level === VIOLATION.L3 ? "warning" : "info",
  });

  logger.warn("gps_violation", {
    uid: userId,
    level: validation.level,
    reason: validation.reason,
  });

  return {
    ok: true,
    valid: false,
    level: validation.level,
    reason: validation.reason,
    rolledBack: true,
    gpsTrustStatus: actions.gpsTrustStatus,
  };
}

const onDriverLocationWrite = onDocumentWritten(
  { document: "users/{userId}", region: FUNCTIONS_REGION },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const db = getFirestore();
    await processDriverLocationWrite(db, {
      userId: event.params.userId,
      before,
      after,
    });
  },
);

function buildRollback(before, after) {
  if (!before) return {};

  const update = {};
  const prevLat =
    before.lastValidLatitude ??
    before.latitude ??
    (before.location && before.location.latitude);
  const prevLng =
    before.lastValidLongitude ??
    before.longitude ??
    (before.location && before.location.longitude);

  if (typeof prevLat === "number" && typeof prevLng === "number") {
    if (after.latitude !== prevLat) update.latitude = prevLat;
    if (after.longitude !== prevLng) update.longitude = prevLng;
    if (after.location) {
      update.location = new GeoPoint(prevLat, prevLng);
    }
    if (after.geohash && before.geohash) {
      update.geohash = before.geohash;
    }
    if (before.locationUpdatedAt) {
      update.locationUpdatedAt = before.locationUpdatedAt;
    }
  }

  return update;
}

module.exports = { onDriverLocationWrite, processDriverLocationWrite };
