/** Haversine distance in meters between two lat/lng points. */
function distanceMeters(lat1, lng1, lat2, lng2) {
  if (
    typeof lat1 !== "number" ||
    typeof lng1 !== "number" ||
    typeof lat2 !== "number" ||
    typeof lng2 !== "number"
  ) {
    return null;
  }
  const R = 6371000;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function isWithinRadiusMeters(lat1, lng1, lat2, lng2, radiusM) {
  const d = distanceMeters(lat1, lng1, lat2, lng2);
  if (d == null) return false;
  return d <= radiusM;
}

module.exports = { distanceMeters, isWithinRadiusMeters };
