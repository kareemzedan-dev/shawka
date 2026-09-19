function approvedContribution(review) {
  if (!review || review.status !== "approved") {
    return { count: 0, sum: 0 };
  }
  const rating = Number(review.rating);
  if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
    return { count: 0, sum: 0 };
  }
  return { count: 1, sum: rating };
}

function contributionDelta(before, after) {
  const previous = approvedContribution(before);
  const next = approvedContribution(after);
  return {
    countDelta: next.count - previous.count,
    sumDelta: next.sum - previous.sum,
  };
}

function applyAggregateDelta(currentCount, currentSum, delta) {
  const count = Math.max(0, Number(currentCount || 0) + delta.countDelta);
  const sum = count === 0
    ? 0
    : Math.max(0, Number(currentSum || 0) + delta.sumDelta);
  return {
    reviewCount: count,
    ratingSum: sum,
    rating: count === 0 ? 0 : sum / count,
  };
}

module.exports = {
  approvedContribution,
  contributionDelta,
  applyAggregateDelta,
};
