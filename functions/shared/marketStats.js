/**
 * Driver market stats — activity level + wait time (Heat State).
 * @see Matlob Delv/docs/DRIVER_MARKET_STATS.md
 */

const DEFAULT_THRESHOLDS = Object.freeze({
  highWaitMinutes: 8,
  lowWaitMinutes: 4,
  lowOffersPerHour: 5,
  highOffersPerHour: 20,
  defaultWaitMinutes: 5,
  minWaitSample: 3,
});

function normalizeGovernorateId(governorate) {
  if (typeof governorate !== "string" || !governorate.trim()) return null;
  return governorate
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_\u0600-\u06FF-]/g, "");
}

function median(values) {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
}

function computeAvgWaitMinutes(waitSamplesMinutes, config) {
  const cfg = { ...DEFAULT_THRESHOLDS, ...config };
  if (!waitSamplesMinutes.length || waitSamplesMinutes.length < cfg.minWaitSample) {
    return cfg.defaultWaitMinutes;
  }
  const med = median(waitSamplesMinutes);
  return Math.max(1, Math.round(med));
}

/**
 * @returns {'low'|'medium'|'high'}
 */
function computeActivityLevel({ avgWaitMinutes, offersLastHour, onlineDriversApprox }, config) {
  const cfg = { ...DEFAULT_THRESHOLDS, ...config };
  const wait = avgWaitMinutes ?? cfg.defaultWaitMinutes;
  const offers = offersLastHour ?? 0;

  if (wait > cfg.highWaitMinutes || offers < cfg.lowOffersPerHour) {
    return "low";
  }
  if (wait <= cfg.lowWaitMinutes && offers >= cfg.highOffersPerHour) {
    return "high";
  }
  return "medium";
}

function buildMarketStatsDoc({
  governorate,
  governorateId,
  avgWaitMinutes,
  onlineDriversApprox,
  offersLastHour,
  acceptsLastHour,
  sampleSizeWait,
  thresholdsUsed,
}) {
  const activityLevel = computeActivityLevel(
    { avgWaitMinutes, offersLastHour, onlineDriversApprox },
    thresholdsUsed,
  );

  return {
    governorate,
    governorateId,
    activityLevel,
    avgWaitMinutes,
    onlineDriversApprox,
    onlineDriversIsApprox: true,
    offersLastHour,
    acceptsLastHour,
    sampleSizeWait,
    refreshCadenceMinutes: 5,
    source: "refreshDriverMarketStats_v1",
    schemaVersion: 1,
    thresholdsUsed,
  };
}

module.exports = {
  DEFAULT_THRESHOLDS,
  normalizeGovernorateId,
  median,
  computeAvgWaitMinutes,
  computeActivityLevel,
  buildMarketStatsDoc,
};
