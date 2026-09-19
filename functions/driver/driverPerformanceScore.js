/**
 * Driver performance score 0–100 from aggregated stats.
 */
function computeDriverPerformanceScore(stats) {
  const rating = typeof stats.avgDriverRating === "number" ? stats.avgDriverRating : 3;
  const acceptRate =
    typeof stats.acceptRate === "number" ? stats.acceptRate : 0.5;
  const completed = typeof stats.completedOrderCount === "number" ? stats.completedOrderCount : 0;
  const cancelled = typeof stats.cancelledByDriverCount === "number" ? stats.cancelledByDriverCount : 0;
  const avgDelivery =
    typeof stats.avgDeliveryMinutes === "number" ? stats.avgDeliveryMinutes : 30;

  const ratingScore = (rating / 5) * 30;
  const acceptScore = Math.min(1, Math.max(0, acceptRate)) * 25;
  const totalDone = completed + cancelled;
  const completionRate = totalDone > 0 ? completed / totalDone : 1;
  const completionScore = completionRate * 25;
  const cancelPenalty = totalDone > 0 ? (cancelled / totalDone) * 15 : 0;
  const deliveryScore = avgDelivery <= 25 ? 20 : avgDelivery <= 40 ? 12 : 5;

  return Math.round(
    Math.min(100, Math.max(0, ratingScore + acceptScore + completionScore + deliveryScore - cancelPenalty)),
  );
}

async function refreshDriverScore(db, driverId) {
  const driverRef = db.collection("users").doc(driverId);
  const snap = await driverRef.get();
  if (!snap.exists) return null;
  const d = snap.data();
  if (d.role !== "delivery") return null;

  const score = computeDriverPerformanceScore(d);
  await driverRef.update({
    driverPerformanceScore: score,
    updatedAt: require("firebase-admin/firestore").FieldValue.serverTimestamp(),
  });
  return score;
}

module.exports = { computeDriverPerformanceScore, refreshDriverScore };
