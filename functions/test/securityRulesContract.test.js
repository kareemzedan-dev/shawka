const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const rules = fs.readFileSync(
  path.join(__dirname, "..", "..", "firestore.rules"),
  "utf8",
);
const storageRules = fs.readFileSync(
  path.join(__dirname, "..", "..", "storage.rules"),
  "utf8",
);

function matchBlock(source, collectionPattern, nextPattern) {
  const start = source.indexOf(collectionPattern);
  assert.notEqual(start, -1, `Missing ${collectionPattern}`);
  const end = source.indexOf(nextPattern, start + collectionPattern.length);
  assert.notEqual(end, -1, `Missing block terminator ${nextPattern}`);
  return source.slice(start, end);
}

test("orders cannot be created or updated directly by customers", () => {
  const block = matchBlock(
    rules,
    "match /orders/{orderId}",
    "match /governorates/{id}",
  );
  assert.match(block, /allow create:\s*if false;/);
  assert.doesNotMatch(
    block,
    /allow update:[\s\S]*resource\.data\.customerId == request\.auth\.uid/,
  );
});

test("checkout idempotency receipts are server-only", () => {
  const block = matchBlock(
    rules,
    "match /checkout_requests/{requestId}",
    "match /governorates/{id}",
  );
  assert.match(block, /allow read, write:\s*if false;/);
});

test("client job queue cannot enqueue assignment jobs", () => {
  const block = matchBlock(
    rules,
    "match /job_queue/{id}",
    "match /analytics_events/{id}",
  );
  assert.match(block, /allow create:\s*if isStaff\(\)/);
  assert.doesNotMatch(block, /'assignOrderRound'/);
});

test("catalog storage writes require image type and size validation", () => {
  for (const storagePath of [
    "match /stores/{storeId}/{allPaths=**}",
    "match /promo_banners/{bannerId}/{allPaths=**}",
    "match /store_categories/{governorateKey}/{categoryId}/{allPaths=**}",
  ]) {
    const start = storageRules.indexOf(storagePath);
    assert.notEqual(start, -1, `Missing ${storagePath}`);
    const block = storageRules.slice(start, start + 500);
    assert.match(block, /isAllowedImageContentType\(\)/);
    assert.match(block, /isWithinCatalogImageSizeLimit\(\)/);
  }
});
