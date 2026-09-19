const { initializeApp, getApps, deleteApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const PROJECT_ID = process.env.GCLOUD_PROJECT || "demo-matlobgo-e2e";

function assertEmulatorEnv() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
      "FIRESTORE_EMULATOR_HOST is not set. Run E2E via: npm run test:e2e:emulator",
    );
  }
}

function initAdmin() {
  assertEmulatorEnv();
  if (getApps().length === 0) {
    initializeApp({ projectId: PROJECT_ID });
  }
  return getFirestore();
}

async function clearFirestore(db) {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const url = `http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
  const response = await fetch(url, { method: "DELETE" });
  if (!response.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${response.status}`);
  }
}

module.exports = {
  PROJECT_ID,
  assertEmulatorEnv,
  initAdmin,
  clearFirestore,
};
