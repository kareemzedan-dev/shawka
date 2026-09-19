const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { rankDrivers, pickNextDriver } = require("../assignment/ranking");
const { getConfig } = require("../shared/config");

describe("ranking", () => {
  const config = getConfig();
  const storeLat = 30.0444;
  const storeLng = 31.2357;

  it("ranks closer drivers higher (lower score)", () => {
    const ranked = rankDrivers(
      [
        {
          id: "far",
          latitude: 30.12,
          longitude: 31.35,
          avgDriverRating: 4.5,
        },
        {
          id: "near",
          latitude: 30.045,
          longitude: 31.236,
          avgDriverRating: 4.0,
        },
      ],
      storeLat,
      storeLng,
      config,
    );

    assert.equal(ranked.length, 1);
    assert.equal(ranked[0].id, "near");
  });

  it("falls back to nearest driver when all are outside radius", () => {
    const ranked = rankDrivers(
      [
        {
          id: "too_far",
          latitude: 31.0,
          longitude: 32.0,
          avgDriverRating: 5,
        },
      ],
      storeLat,
      storeLng,
      config,
    );
    assert.equal(ranked.length, 1);
    assert.equal(ranked[0].id, "too_far");
  });

  it("pickNextDriver skips rejected ids", () => {
    const ranked = [
      { id: "a", score: 1 },
      { id: "b", score: 2 },
      { id: "c", score: 3 },
    ];
    const next = pickNextDriver(ranked, ["a", "b"]);
    assert.equal(next.id, "c");
  });

  it("pickNextDriver returns null when all rejected", () => {
    const ranked = [{ id: "a", score: 1 }];
    assert.equal(pickNextDriver(ranked, ["a"]), null);
  });

  it("pickNextDriver re-offers when exhausted and allowRejectedWhenExhausted", () => {
    const ranked = [{ id: "a", score: 1 }];
    const next = pickNextDriver(ranked, ["a"], {
      allowRejectedWhenExhausted: true,
    });
    assert.equal(next.id, "a");
  });
});
