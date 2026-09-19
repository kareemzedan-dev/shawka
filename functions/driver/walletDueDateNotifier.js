const { onSchedule } = require("firebase-functions/v2/scheduler");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { loadWalletThresholds } = require("../shared/walletThresholds");
const { sendWalletPush } = require("../shared/driverWallet");

const MS_HOUR = 60 * 60 * 1000;

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

async function runWalletDueDateNotifier(db) {
  const thresholds = await loadWalletThresholds(db);
  const windowMs = thresholds.settlementWindowHours * MS_HOUR;
  const warnBeforeMs = 24 * MS_HOUR;
  const now = Date.now();

  const snap = await db
    .collection("users")
    .where("role", "==", "delivery")
    .where("outstandingBalance", ">", 0)
    .limit(500)
    .get();

  let notified = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const outstanding = data.outstandingBalance || 0;
    if (outstanding <= 0) continue;

    const lastCod = toDate(data.lastCodCollectionAt);
    if (!lastCod) continue;

    const dueAt = lastCod.getTime() + windowMs;
    const remaining = dueAt - now;

    if (remaining > warnBeforeMs || remaining <= 0) continue;

    const lastNotified = toDate(data.walletDueNotifiedAt);
    if (lastNotified && now - lastNotified.getTime() < 12 * MS_HOUR) {
      continue;
    }

    const token =
      typeof data.fcmToken === "string" && data.fcmToken.length > 10
        ? data.fcmToken
        : null;
    if (!token) continue;

    await sendWalletPush({
      token,
      title: "موعد التسوية",
      body: "متبقي أقل من 24 ساعة على موعد تسوية المبالغ المستحقة.",
      type: "wallet_due_soon",
      route: "/wallet",
    });

    await doc.ref.update({
      walletDueNotifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    notified += 1;
  }

  logger.info("walletDueDateNotifier completed", {
    driversChecked: snap.size,
    notified,
  });

  return { driversChecked: snap.size, notified };
}

const walletDueDateNotifier = onSchedule(
  {
    region: FUNCTIONS_REGION,
    schedule: "every 1 hours",
    timeZone: "Africa/Cairo",
  },
  async () => {
    const db = getFirestore();
    await runWalletDueDateNotifier(db);
  },
);

module.exports = {
  walletDueDateNotifier,
  runWalletDueDateNotifier,
};
