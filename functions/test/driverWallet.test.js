const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const { mapTransactionType, LEGACY_TYPE_MAP } = require("../shared/driverWallet");

describe("driverWallet audit mapping", () => {
  it("maps legacy wallet transaction types", () => {
    assert.equal(mapTransactionType("delivery_earnings"), "earning");
    assert.equal(mapTransactionType("cod_collection"), "cod_collection");
    assert.equal(mapTransactionType("settlement"), "settlement");
    assert.equal(mapTransactionType("delivery_completed"), "earning");
  });

  it("passes through canonical V2 types", () => {
    assert.equal(mapTransactionType("bonus"), "bonus");
    assert.equal(mapTransactionType("refund"), "refund");
  });

  it("exports full legacy map", () => {
    assert.ok(LEGACY_TYPE_MAP.cod_collection);
    assert.equal(LEGACY_TYPE_MAP.adjustment, "manual_adjustment");
  });
});
