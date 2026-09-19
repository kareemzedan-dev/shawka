const test = require("node:test");
const assert = require("node:assert/strict");
const { collectDeltas } = require("../favorites");

test("favorite create increments store total", () => {
  assert.deepEqual(
    collectDeltas(null, { type: "store", storeId: "s1", productId: "" }),
    [{ path: "stores/s1", field: "totalFavorites", delta: 1 }],
  );
});

test("product favorite create increments store and product counters", () => {
  assert.deepEqual(
    collectDeltas(null, { type: "product", storeId: "s1", productId: "p1" }),
    [
      { path: "stores/s1", field: "totalFavorites", delta: 1 },
      {
        path: "stores/s1/products/p1",
        field: "favoritesCount",
        delta: 1,
      },
    ],
  );
});

test("favorite delete decrements counters", () => {
  assert.deepEqual(
    collectDeltas({ type: "product", storeId: "s1", productId: "p1" }, null),
    [
      { path: "stores/s1", field: "totalFavorites", delta: -1 },
      {
        path: "stores/s1/products/p1",
        field: "favoritesCount",
        delta: -1,
      },
    ],
  );
});

test("no-op update produces no deltas", () => {
  const favorite = { type: "product", storeId: "s1", productId: "p1" };
  assert.deepEqual(collectDeltas(favorite, favorite), []);
});

test("moving a favorite between products shifts product counters only", () => {
  assert.deepEqual(
    collectDeltas(
      { type: "product", storeId: "s1", productId: "p1" },
      { type: "product", storeId: "s1", productId: "p2" },
    ),
    [
      {
        path: "stores/s1/products/p1",
        field: "favoritesCount",
        delta: -1,
      },
      {
        path: "stores/s1/products/p2",
        field: "favoritesCount",
        delta: 1,
      },
    ],
  );
});

test("invalid favorites are ignored", () => {
  assert.deepEqual(collectDeltas(null, null), []);
  assert.deepEqual(collectDeltas(null, { type: "store" }), []);
  assert.deepEqual(
    collectDeltas(null, { type: "product", storeId: "s1", productId: "" }),
    [{ path: "stores/s1", field: "totalFavorites", delta: 1 }],
  );
});
