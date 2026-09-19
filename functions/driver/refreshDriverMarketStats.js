const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  normalizeGovernorateId,
  computeAvgWaitMinutes,
  buildMarketStatsDoc,
  DEFAULT_THRESHOLDS,
} = require("../shared/marketStats");

const OFFERS_WINDOW_MS = 60 * 60 * 1000;
const WAIT_WINDOW_MS = 180 * 60 * 1000;

function toMillis(ts) {
  if (!ts) return null;
  if (typeof ts.toMillis === "function") return ts.toMillis();
  if (ts instanceof Date) return ts.getTime();
  return null;
}

async function collectOnlineByGovernorate(db) {
  const snap = await db
    .collection("users")
    .where("role", "==", "delivery")
    .where("isDriverOnline", "==", true)
    .where("driverApprovalStatus", "==", "approved")
    .get();

  const counts = new Map();
  const names = new Map();

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.isActive === false) continue;
    const gov = data.governorate;
    const id = normalizeGovernorateId(gov);
    if (!id) continue;
    counts.set(id, (counts.get(id) || 0) + 1);
    if (gov && !names.has(id)) names.set(id, gov);
  }

  return { counts, names };
}

async function collectOrderMetrics(db, governorateId, displayName) {
  const now = Date.now();
  const offersSince = now - OFFERS_WINDOW_MS;
  const waitSince = now - WAIT_WINDOW_MS;

  const snap = await db
    .collection("orders")
    .where("governorate", "==", displayName)
    .where("updatedAt", ">=", new Date(waitSince))
    .limit(500)
    .get();

  let offersLastHour = 0;
  let acceptsLastHour = 0;
  const waitSamplesMinutes = [];

  for (const doc of snap.docs) {
    const o = doc.data();
    const offeredAt = toMillis(o.offeredAt);
    const acceptedAt = toMillis(o.deliveryAcceptedAt);

    if (offeredAt != null && offeredAt >= offersSince) {
      offersLastHour += 1;
    }
    if (acceptedAt != null && acceptedAt >= offersSince) {
      acceptsLastHour += 1;
    }
    if (offeredAt != null && acceptedAt != null && offeredAt >= waitSince) {
      waitSamplesMinutes.push((acceptedAt - offeredAt) / 60000);
    }
  }

  return { offersLastHour, acceptsLastHour, waitSamplesMinutes };
}

async function refreshAllMarketStats(db, config) {
  const thresholdsUsed = { ...DEFAULT_THRESHOLDS, ...config };
  const { counts, names } = await collectOnlineByGovernorate(db);
  const governorateIds = new Set(counts.keys());

  let written = 0;
  for (const governorateId of governorateIds) {
    const displayName = names.get(governorateId) || governorateId;
    const onlineDriversApprox = counts.get(governorateId) || 0;

    let orderMetrics = {
      offersLastHour: 0,
      acceptsLastHour: 0,
      waitSamplesMinutes: [],
    };
    try {
      orderMetrics = await collectOrderMetrics(db, governorateId, displayName);
    } catch (err) {
      logger.warn("market_stats_orders_query_failed", {
        governorateId,
        error: String(err),
      });
    }

    const avgWaitMinutes = computeAvgWaitMinutes(
      orderMetrics.waitSamplesMinutes,
      thresholdsUsed,
    );

    const payload = buildMarketStatsDoc({
      governorate: displayName,
      governorateId,
      avgWaitMinutes,
      onlineDriversApprox,
      offersLastHour: orderMetrics.offersLastHour,
      acceptsLastHour: orderMetrics.acceptsLastHour,
      sampleSizeWait: orderMetrics.waitSamplesMinutes.length,
      thresholdsUsed,
    });

    await db.collection("driver_market_stats").doc(governorateId).set(
      {
        ...payload,
        refreshedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    written += 1;
  }

  return { written, governorates: governorateIds.size };
}

const refreshDriverMarketStats = onSchedule(
  { schedule: "every 5 minutes", region: FUNCTIONS_REGION },
  async () => {
    const db = getFirestore();
    const result = await refreshAllMarketStats(db, {});
    logger.info("driver_market_stats_refreshed", result);
  },
);

module.exports = {
  refreshDriverMarketStats,
  refreshAllMarketStats,
  collectOnlineByGovernorate,
  collectOrderMetrics,
};
