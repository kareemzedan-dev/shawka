const { distanceKm } = require("../shared/geohash");

/**
 * Rank driver candidates by distance, rating, and recency of last offer.
 * Lower score = better candidate.
 */
function scoreCandidate(driver, storeLat, storeLng, config, now, radiusKm) {
  const lat = driver._coords?.lat ?? driver.latitude;
  const lng = driver._coords?.lng ?? driver.longitude;
  if (typeof lat !== "number" || typeof lng !== "number") return null;

  const dist = distanceKm(storeLat, storeLng, lat, lng);
  if (radiusKm != null && dist > radiusKm) return null;

  const rating =
    typeof driver.avgDriverRating === "number" ? driver.avgDriverRating : 3.0;
  const ratingBonus = (5 - rating) * 0.05;

  let lastOfferPenalty = 0;
  const lastOffered = driver.lastOfferedAt;
  if (lastOffered) {
    const ms =
      typeof lastOffered.toMillis === "function"
        ? lastOffered.toMillis()
        : lastOffered instanceof Date
          ? lastOffered.getTime()
          : null;
    if (ms != null && now - ms < 5 * 60 * 1000) {
      lastOfferPenalty = 0.5;
    }
  }

  const acceptRate =
    typeof driver.acceptRate === "number" ? driver.acceptRate : 0.5;
  const acceptBonus = (1 - acceptRate) * 0.1;

  const score = dist + ratingBonus + lastOfferPenalty + acceptBonus;

  return {
    id: driver.id,
    score,
    distanceKm: dist,
    driver,
  };
}

function rankDrivers(candidates, storeLat, storeLng, config, round = 1) {
  const baseRadius = config?.driver_assignment_radius_km ?? 8.0;
  const radiusKm = baseRadius * Math.min(Math.max(round, 1), 4);
  const now = Date.now();

  let scored = candidates
    .map((driver) => scoreCandidate(driver, storeLat, storeLng, config, now, radiusKm))
    .filter(Boolean);

  // Single-market fallback: if every driver is outside radius, offer nearest anyway.
  if (scored.length === 0 && candidates.length > 0) {
    scored = candidates
      .map((driver) =>
        scoreCandidate(driver, storeLat, storeLng, config, now, null),
      )
      .filter(Boolean);
  }

  scored.sort((a, b) => a.score - b.score);
  return scored;
}

function pickNextDriver(ranked, rejectedIds = [], options = {}) {
  const rejected = new Set(rejectedIds);
  for (const entry of ranked) {
    if (!rejected.has(entry.id)) return entry;
  }
  if (options.allowRejectedWhenExhausted && ranked.length > 0) {
    return ranked[0];
  }
  return null;
}

module.exports = { rankDrivers, pickNextDriver };
