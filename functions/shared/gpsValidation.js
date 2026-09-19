const { distanceMeters } = require("./geohash");
const { maxSpeedKmh } = require("./config");

const JUMP_THRESHOLDS = Object.freeze({
  bicycle: { maxJumpM: 200, extremeJumpM: 1000, windowSec: 15 },
  motorcycle: { maxJumpM: 500, extremeJumpM: 2000, windowSec: 15 },
  car: { maxJumpM: 500, extremeJumpM: 2000, windowSec: 15 },
});

const VIOLATION = Object.freeze({
  NONE: "none",
  L1: "L1",
  L2: "L2",
  L3: "L3",
  L4: "L4",
  L5: "L5",
});

function jumpConfig(vehicleType) {
  if (vehicleType === "bicycle") return JUMP_THRESHOLDS.bicycle;
  return JUMP_THRESHOLDS.motorcycle;
}

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts === "number") return ts;
  if (ts instanceof Date) return ts.getTime();
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (typeof ts.toDate === "function") return ts.toDate().getTime();
  return null;
}

/**
 * Validate a GPS update against last valid point — §11.1 contract.
 * @returns {{ valid: boolean, level: string, reason?: string, impliedSpeedKmh?: number, distanceM?: number }}
 */
function validateGpsUpdate({
  vehicleType = "motorcycle",
  lastValidLatitude,
  lastValidLongitude,
  lastValidLocationAt,
  newLatitude,
  newLongitude,
  nowMs = Date.now(),
  config,
}) {
  if (
    typeof newLatitude !== "number" ||
    typeof newLongitude !== "number" ||
    newLatitude < -90 ||
    newLatitude > 90 ||
    newLongitude < -180 ||
    newLongitude > 180
  ) {
    return { valid: false, level: VIOLATION.L2, reason: "invalid_coordinates" };
  }

  if (
    typeof lastValidLatitude !== "number" ||
    typeof lastValidLongitude !== "number" ||
    lastValidLatitude == null
  ) {
    return { valid: true, level: VIOLATION.NONE, reason: "first_fix" };
  }

  const lastMs = toMillis(lastValidLocationAt);
  const timeDeltaSec =
    lastMs != null ? Math.max(0.001, (nowMs - lastMs) / 1000) : 15;
  const distM = distanceMeters(
    lastValidLatitude,
    lastValidLongitude,
    newLatitude,
    newLongitude,
  );
  const timeDeltaHours = timeDeltaSec / 3600;
  const impliedSpeedKmh =
    timeDeltaHours > 0 ? distM / 1000 / timeDeltaHours : 0;

  const maxSpeed = maxSpeedKmh(vehicleType, config);
  const jump = jumpConfig(vehicleType);

  if (distM > jump.extremeJumpM) {
    return {
      valid: false,
      level: VIOLATION.L3,
      reason: "extreme_jump",
      impliedSpeedKmh,
      distanceM: distM,
    };
  }

  if (impliedSpeedKmh > maxSpeed * 2) {
    return {
      valid: false,
      level: VIOLATION.L3,
      reason: "speed_200pct",
      impliedSpeedKmh,
      distanceM: distM,
    };
  }

  if (impliedSpeedKmh > maxSpeed * 1.2) {
    return {
      valid: false,
      level: VIOLATION.L2,
      reason: "speed_exceeded",
      impliedSpeedKmh,
      distanceM: distM,
    };
  }

  if (impliedSpeedKmh > maxSpeed) {
    return {
      valid: false,
      level: VIOLATION.L1,
      reason: "speed_minor",
      impliedSpeedKmh,
      distanceM: distM,
    };
  }

  if (timeDeltaSec <= jump.windowSec && distM > jump.maxJumpM) {
    return {
      valid: false,
      level: VIOLATION.L2,
      reason: "jump_threshold",
      impliedSpeedKmh,
      distanceM: distM,
    };
  }

  return {
    valid: true,
    level: VIOLATION.NONE,
    impliedSpeedKmh,
    distanceM: distM,
  };
}

/**
 * Map violation count to trust actions — §11.1.4.
 */
function trustActionsForViolation(level, currentCount24h = 0) {
  const actions = {
    rollback: level !== VIOLATION.NONE && level !== VIOLATION.L1,
    incrementCounter: level === VIOLATION.L2 || level === VIOLATION.L3,
    gpsTrustStatus: null,
    assignmentEligibleUntilMs: null,
    queueAdminReview: false,
  };

  if (level === VIOLATION.L3) {
    actions.gpsTrustStatus = "restricted";
    actions.assignmentEligibleUntilMs = Date.now() + 60 * 60 * 1000;
  }

  const nextCount =
    actions.incrementCounter ? currentCount24h + 1 : currentCount24h;

  if (nextCount >= 3) {
    actions.gpsTrustStatus = "restricted";
    actions.assignmentEligibleUntilMs = Date.now() + 60 * 60 * 1000;
  }
  if (nextCount >= 3 && level !== VIOLATION.L1) {
    if (nextCount >= 5) {
      actions.gpsTrustStatus = "suspended";
      actions.assignmentEligibleUntilMs = Date.now() + 24 * 60 * 60 * 1000;
    }
  }

  if (nextCount >= 5) {
    actions.queueAdminReview = true;
  }

  return actions;
}

module.exports = {
  VIOLATION,
  JUMP_THRESHOLDS,
  validateGpsUpdate,
  trustActionsForViolation,
  jumpConfig,
};
