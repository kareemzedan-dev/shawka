const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { loadWalletThresholds } = require("../shared/walletThresholds");
const { logOpsIncident } = require("../shared/opsIncidents");
const { trackAnalyticsEventInternal } = require("../shared/analyticsInternal");

const MS_DAY = 24 * 60 * 60 * 1000;

async function countAnalyticsEvents(db, { userId, type, sinceMs }) {
  const since = Timestamp.fromMillis(sinceMs);
  const snap = await db
    .collection("analytics_events")
    .where("userId", "==", userId)
    .where("type", "==", type)
    .where("createdAt", ">=", since)
    .get();
  return snap.size;
}

async function countOutstandingViolations(db, driverId, blockLevel, sinceMs) {
  const since = Timestamp.fromMillis(sinceMs);
  const snap = await db
    .collection("analytics_events")
    .where("userId", "==", driverId)
    .where("type", "==", "driver_cash_blocked")
    .where("createdAt", ">=", since)
    .get();
  return snap.size;
}

async function hasConsecutiveRejectedRequests(db, driverId, count) {
  const snap = await db
    .collection("settlement_requests")
    .where("driverId", "==", driverId)
    .orderBy("createdAt", "desc")
    .limit(count)
    .get();
  if (snap.size < count) return false;
  return snap.docs.every((doc) => doc.data().status === "rejected");
}

async function evaluateDriverFinancialRisk(db, driverId, driver, thresholds, now) {
  const risks = [];

  const blockCount30d = await countAnalyticsEvents(db, {
    userId: driverId,
    type: "driver_cash_blocked",
    sinceMs: now - 30 * MS_DAY,
  });
  if (blockCount30d >= thresholds.financialRiskBlockCount) {
    risks.push({
      level: 1,
      severity: "medium",
      message: `المندوب ${driver.name || driverId} — حظر مالي ${blockCount30d} مرات خلال 30 يوم`,
      details: { blockCount30d, windowDays: 30 },
    });
  }

  const violations60d = await countOutstandingViolations(
    db,
    driverId,
    thresholds.blockLevel,
    now - 60 * MS_DAY,
  );
  if (violations60d >= thresholds.financialRiskOutstandingViolations) {
    risks.push({
      level: 2,
      severity: "high",
      message: `المندوب ${driver.name || driverId} — تجاوز الحد النهائي ${violations60d} مرات خلال 60 يوم`,
      details: {
        violations60d,
        blockLevel: thresholds.blockLevel,
        windowDays: 60,
      },
    });
  }

  const consecutiveRejected = await hasConsecutiveRejectedRequests(
    db,
    driverId,
    3,
  );
  if (consecutiveRejected) {
    risks.push({
      level: 3,
      severity: "critical",
      message: `المندوب ${driver.name || driverId} — 3 طلبات تسوية مرفوضة متتالية`,
      details: { consecutiveRejectedRequests: 3 },
    });
  }

  return risks;
}

async function runFinancialRiskMonitor(db) {
  const thresholds = await loadWalletThresholds(db);
  const now = Date.now();

  const driversSnap = await db
    .collection("users")
    .where("role", "==", "delivery")
    .where("outstandingBalance", ">", 0)
    .limit(500)
    .get();

  const driverIds = new Set(driversSnap.docs.map((d) => d.id));

  const blockedSnap = await db
    .collection("users")
    .where("role", "==", "delivery")
    .where("driverCashBlocked", "==", true)
    .limit(200)
    .get();
  for (const doc of blockedSnap.docs) {
    driverIds.add(doc.id);
  }

  let incidentsCreated = 0;

  for (const driverId of driverIds) {
    const driverSnap = await db.collection("users").doc(driverId).get();
    if (!driverSnap.exists) continue;
    const driver = driverSnap.data();

    const risks = await evaluateDriverFinancialRisk(
      db,
      driverId,
      driver,
      thresholds,
      now,
    );

    for (const risk of risks) {
      const dedupeKey = `driver_financial_risk_${driverId}_L${risk.level}`;
      const recentSnap = await db
        .collection("ops_incidents")
        .where("type", "==", "driver_financial_risk")
        .where("driverId", "==", driverId)
        .where("resolutionStatus", "==", "open")
        .limit(5)
        .get();

      const alreadyOpen = recentSnap.docs.some(
        (doc) => doc.data()?.details?.riskLevel === risk.level,
      );
      if (alreadyOpen) continue;

      await logOpsIncident(db, {
        type: "driver_financial_risk",
        severity: risk.severity,
        message: risk.message,
        driverId,
        details: {
          riskLevel: risk.level,
          dedupeKey,
          ...risk.details,
        },
      });

      await trackAnalyticsEventInternal(db, {
        type: "driver_financial_risk_detected",
        userId: driverId,
        screen: "financial_risk_monitor",
        metadata: { riskLevel: risk.level, severity: risk.severity },
      });

      incidentsCreated += 1;
    }
  }

  logger.info("financialRiskMonitor completed", {
    driversScanned: driverIds.size,
    incidentsCreated,
  });

  return { driversScanned: driverIds.size, incidentsCreated };
}

const financialRiskMonitor = onSchedule(
  {
    region: FUNCTIONS_REGION,
    schedule: "every 6 hours",
    timeZone: "Africa/Cairo",
  },
  async () => {
    const db = getFirestore();
    await runFinancialRiskMonitor(db);
  },
);

module.exports = {
  financialRiskMonitor,
  runFinancialRiskMonitor,
  evaluateDriverFinancialRisk,
};
