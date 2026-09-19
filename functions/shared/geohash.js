const ngeohash = require("ngeohash");

const EARTH_RADIUS_KM = 6371;

/**
 * Haversine distance in metres between two lat/lng points.
 */
function distanceMeters(lat1, lng1, lat2, lng2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c * 1000;
}

function distanceKm(lat1, lng1, lat2, lng2) {
  return distanceMeters(lat1, lng1, lat2, lng2) / 1000;
}

function encodeGeohash(lat, lng, precision = 7) {
  return ngeohash.encode(lat, lng, precision);
}

function decodeGeohash(hash) {
  return ngeohash.decode(hash);
}

/**
 * Geohash precision shrinks with assignment round (wider search each round).
 */
function precisionForRound(round) {
  const r = Math.max(1, round || 1);
  if (r <= 1) return 6;
  if (r <= 2) return 5;
  if (r <= 3) return 4;
  return 3;
}

/**
 * Bounding box for a geohash prefix query (approximate).
 */
function boundsForGeohash(hash) {
  return ngeohash.decode_bbox(hash);
}

/**
 * Neighbour geohashes for expanding search radius per round.
 */
function neighboursForRound(centerLat, centerLng, round) {
  const precision = precisionForRound(round);
  const center = encodeGeohash(centerLat, centerLng, precision);
  const visited = new Set([center]);
  const queue = [center];

  const expandSteps = Math.min(round, 3);
  for (let step = 0; step < expandSteps; step += 1) {
    const next = [];
    for (const hash of queue) {
      const neigh = ngeohash.neighbors(hash);
      for (const n of Object.values(neigh)) {
        if (!visited.has(n)) {
          visited.add(n);
          next.push(n);
        }
      }
    }
    queue.push(...next);
  }

  return [...visited];
}

function extractLatLng(user) {
  if (typeof user.latitude === "number" && typeof user.longitude === "number") {
    return { lat: user.latitude, lng: user.longitude };
  }
  const loc = user.location;
  if (loc && typeof loc.latitude === "number" && typeof loc.longitude === "number") {
    return { lat: loc.latitude, lng: loc.longitude };
  }
  if (loc && typeof loc._latitude === "number" && typeof loc._longitude === "number") {
    return { lat: loc._latitude, lng: loc._longitude };
  }
  if (
    typeof user.lastValidLatitude === "number" &&
    typeof user.lastValidLongitude === "number"
  ) {
    return { lat: user.lastValidLatitude, lng: user.lastValidLongitude };
  }
  return null;
}

module.exports = {
  distanceMeters,
  distanceKm,
  encodeGeohash,
  decodeGeohash,
  precisionForRound,
  boundsForGeohash,
  neighboursForRound,
  extractLatLng,
};
