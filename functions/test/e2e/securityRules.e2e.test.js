const test = require("node:test");
const assert = require("node:assert/strict");

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  "demo-matlobgo-e2e";
const host = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
const base =
  `http://${host}/v1/projects/${projectId}/databases/(default)/documents`;

function base64Url(value) {
  return Buffer.from(JSON.stringify(value)).toString("base64url");
}

function authToken(uid, claims = {}) {
  const now = Math.floor(Date.now() / 1000);
  return [
    base64Url({ alg: "none", typ: "JWT" }),
    base64Url({
      aud: projectId,
      auth_time: now,
      exp: now + 3600,
      firebase: { identities: {}, sign_in_provider: "custom" },
      iat: now,
      iss: `https://securetoken.google.com/${projectId}`,
      sub: uid,
      user_id: uid,
      ...claims,
    }),
    "",
  ].join(".");
}

async function write(path, fields, token = "owner") {
  return fetch(`${base}/${path}`, {
    method: "PATCH",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
}

test("customer cannot create an order directly", async () => {
  const response = await write(
    "orders/forged-order",
    {
      customerId: { stringValue: "customer-1" },
      storeId: { stringValue: "store-1" },
      status: { stringValue: "pending" },
      total: { doubleValue: 0.01 },
    },
    authToken("customer-1", { role: "customer" }),
  );
  assert.equal(response.status, 403);
});

test("customer cannot enqueue privileged assignment jobs", async () => {
  const response = await write(
    "job_queue/forged-assignment",
    {
      type: { stringValue: "assignOrderRound" },
      status: { stringValue: "pending" },
      priority: { stringValue: "high" },
      payload: { mapValue: { fields: {} } },
      createdAt: { timestampValue: new Date().toISOString() },
    },
    authToken("customer-1", { role: "customer" }),
  );
  assert.equal(response.status, 403);
});

test("customer can read own order but not another customer's order", async () => {
  await write("orders/owned-order", {
    customerId: { stringValue: "customer-1" },
    storeId: { stringValue: "store-1" },
    status: { stringValue: "pending" },
  });

  const ownToken = authToken("customer-1", { role: "customer" });
  const otherToken = authToken("customer-2", { role: "customer" });
  const own = await fetch(`${base}/orders/owned-order`, {
    headers: { authorization: `Bearer ${ownToken}` },
  });
  const other = await fetch(`${base}/orders/owned-order`, {
    headers: { authorization: `Bearer ${otherToken}` },
  });

  assert.equal(own.status, 200);
  assert.equal(other.status, 403);
});
