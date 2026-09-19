const { getRemoteConfig } = require("firebase-admin/remote-config");
const { logger } = require("firebase-functions");

/**
 * Remote Config defaults — mirror Matlob Delv remote_config_keys.dart / §5 contract.
 * Cloud Functions now consume the same Firebase Remote Config template.
 */
const DEFAULTS = Object.freeze({
  driver_assignment_accept_seconds: 45,
  driver_assignment_max_rounds: 5,
  driver_assignment_radius_km: 8.0,
  driver_assignment_candidates_per_round: 50,
  driver_gps_update_interval_seconds: 15,
  driver_gps_min_distance_meters: 50,
  driver_background_location_enabled: true,
  driver_presence_heartbeat_seconds: 60,
  driver_presence_offline_threshold_seconds: 180,
  driver_presence_location_stale_seconds: 600,
  driver_max_document_upload_size_mb: 5,
  driver_gps_max_speed_bicycle_kmh: 35,
  driver_gps_max_speed_motorcycle_kmh: 120,
  driver_gps_max_speed_car_kmh: 160,
});

const VALID_VEHICLE_TYPES = new Set(["bicycle", "motorcycle", "car"]);
const CACHE_TTL_MS = 5 * 60 * 1000;
let cachedRuntimeConfig = null;
let cacheExpiresAt = 0;

function getConfig(overrides = {}) {
  const merged = { ...DEFAULTS };
  for (const [key, value] of Object.entries(overrides || {})) {
    if (!(key in DEFAULTS)) continue;
    const fallback = DEFAULTS[key];
    if (typeof fallback === "boolean") {
      if (value === true || value === "true") merged[key] = true;
      if (value === false || value === "false") merged[key] = false;
      continue;
    }
    const number = Number(value);
    if (Number.isFinite(number)) merged[key] = number;
  }
  return sanitizeConfig(merged);
}

function sanitizeConfig(config) {
  return {
    ...config,
    driver_assignment_accept_seconds: Math.round(
      Math.min(180, Math.max(10, config.driver_assignment_accept_seconds)),
    ),
    driver_assignment_max_rounds: Math.round(
      Math.min(10, Math.max(1, config.driver_assignment_max_rounds)),
    ),
    driver_assignment_radius_km: Math.min(
      50,
      Math.max(1, config.driver_assignment_radius_km),
    ),
    driver_assignment_candidates_per_round: Math.round(
      Math.min(100, Math.max(1, config.driver_assignment_candidates_per_round)),
    ),
  };
}

function templateOverrides(template) {
  const overrides = {};
  for (const key of Object.keys(DEFAULTS)) {
    const parameter = template?.parameters?.[key];
    const raw = parameter?.defaultValue?.value;
    if (raw !== undefined) overrides[key] = raw;
  }
  return overrides;
}

async function getRuntimeConfig({ forceRefresh = false } = {}) {
  const now = Date.now();
  if (!forceRefresh && cachedRuntimeConfig && now < cacheExpiresAt) {
    return cachedRuntimeConfig;
  }

  try {
    const template = await getRemoteConfig().getTemplate();
    cachedRuntimeConfig = getConfig(templateOverrides(template));
    cacheExpiresAt = now + CACHE_TTL_MS;
    return cachedRuntimeConfig;
  } catch (error) {
    logger.error("remote_config_fetch_failed", { error: String(error) });
    // Fail safely with validated defaults; never block assignment.
    cachedRuntimeConfig = getConfig();
    cacheExpiresAt = now + Math.min(CACHE_TTL_MS, 60 * 1000);
    return cachedRuntimeConfig;
  }
}

function maxSpeedKmh(vehicleType, config) {
  const cfg = config || DEFAULTS;
  switch (vehicleType) {
    case "bicycle":
      return cfg.driver_gps_max_speed_bicycle_kmh;
    case "motorcycle":
      return cfg.driver_gps_max_speed_motorcycle_kmh;
    case "car":
      return cfg.driver_gps_max_speed_car_kmh;
    default:
      return cfg.driver_gps_max_speed_motorcycle_kmh;
  }
}

module.exports = {
  DEFAULTS,
  VALID_VEHICLE_TYPES,
  getConfig,
  getRuntimeConfig,
  templateOverrides,
  maxSpeedKmh,
};
