const test = require("node:test");
const assert = require("node:assert/strict");
const {
  approvedContribution,
  contributionDelta,
  applyAggregateDelta,
} = require("../reviewsCore");

test("only approved reviews contribute to aggregates", () => {
  assert.deepEqual(
    approvedContribution({ status: "approved", rating: 5 }),
    { count: 1, sum: 5 },
  );
  assert.deepEqual(
    approvedContribution({ status: "pending", rating: 5 }),
    { count: 0, sum: 0 },
  );
});

test("calculates create, delete, rating, and moderation deltas", () => {
  assert.deepEqual(
    contributionDelta(null, { status: "approved", rating: 4 }),
    { countDelta: 1, sumDelta: 4 },
  );
  assert.deepEqual(
    contributionDelta(
      { status: "approved", rating: 4 },
      { status: "approved", rating: 2 },
    ),
    { countDelta: 0, sumDelta: -2 },
  );
  assert.deepEqual(
    contributionDelta(
      { status: "approved", rating: 3 },
      { status: "rejected", rating: 3 },
    ),
    { countDelta: -1, sumDelta: -3 },
  );
});

test("applies aggregate deltas and resets empty aggregates", () => {
  assert.deepEqual(
    applyAggregateDelta(2, 7, { countDelta: 1, sumDelta: 5 }),
    { reviewCount: 3, ratingSum: 12, rating: 4 },
  );
  assert.deepEqual(
    applyAggregateDelta(1, 5, { countDelta: -1, sumDelta: -5 }),
    { reviewCount: 0, ratingSum: 0, rating: 0 },
  );
});
