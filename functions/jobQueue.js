const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("./shared/region");

const MAX_ATTEMPTS = 5;
const BATCH_SIZE = 15;

/**
 * معالج طابور المهام — بديل Workers/Redis على Firebase.
 * المهام في `job_queue` تُعالَج بمعاملات claim لتجنب التكرار.
 */
async function claimJob(db, doc) {
  const ref = db.collection("job_queue").doc(doc.id);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const data = snap.data();
    if (data.status !== "pending") return null;
    if ((data.attempts || 0) >= MAX_ATTEMPTS) {
      tx.update(ref, {
        status: "failed",
        error: "max_attempts",
        completedAt: FieldValue.serverTimestamp(),
      });
      return null;
    }
    tx.update(ref, {
      status: "processing",
      attempts: (data.attempts || 0) + 1,
      startedAt: FieldValue.serverTimestamp(),
    });
    return { id: doc.id, ...data };
  });
}

async function completeJob(db, jobId, extra = {}) {
  await db.collection("job_queue").doc(jobId).update({
    status: "completed",
    completedAt: FieldValue.serverTimestamp(),
    ...extra,
  });
}

async function failJob(db, jobId, error) {
  await db.collection("job_queue").doc(jobId).update({
    status: "failed",
    error: String(error).slice(0, 500),
    completedAt: FieldValue.serverTimestamp(),
  });
}

async function processJob(db, job) {
  const type = job.type || "";
  const payload = job.payload || {};

  switch (type) {
    case "catalogWarmup":
      logger.info("catalogWarmup job", {
        jobId: job.id,
        governorate: payload.governorate,
      });
      await completeJob(db, job.id, { result: "warmup_ack" });
      return;

    case "analyticsBatch":
      logger.info("analyticsBatch job", { jobId: job.id });
      await completeJob(db, job.id, { result: "batch_ack" });
      return;

    case "reportExport":
      logger.info("reportExport job", { jobId: job.id, spec: payload });
      await completeJob(db, job.id, { result: "export_queued" });
      return;

    case "pushRetry":
      logger.info("pushRetry job", { jobId: job.id });
      await completeJob(db, job.id, { result: "retry_ack" });
      return;

    case "assignOrderRound": {
      const { runAssignOrderRound } = require("./assignment/assignOrderRound");
      const orderId = payload.orderId;
      if (typeof orderId !== "string" || !orderId) {
        await failJob(db, job.id, "missing_orderId");
        return;
      }
      const result = await runAssignOrderRound(db, {
        orderId,
        round: payload.round,
        operationId: payload.operationId,
      });
      await completeJob(db, job.id, { result: result || "assigned" });
      return;
    }

    default:
      await failJob(db, job.id, `unknown_type:${type}`);
  }
}

async function drainQueue(db) {
  const snap = await db
    .collection("job_queue")
    .where("status", "==", "pending")
    .orderBy("createdAt", "asc")
    .limit(BATCH_SIZE)
    .get();

  if (snap.empty) return 0;

  let processed = 0;
  for (const doc of snap.docs) {
    try {
      const claimed = await claimJob(db, doc);
      if (!claimed) continue;
      await processJob(db, claimed);
      processed += 1;
    } catch (err) {
      logger.error("job failed", { jobId: doc.id, error: String(err) });
      await failJob(db, doc.id, err);
    }
  }
  return processed;
}

exports.processJobQueue = onSchedule("every 1 minutes", async () => {
  const db = getFirestore();
  const count = await drainQueue(db);
  if (count > 0) {
    logger.info("Job queue drained", { processed: count });
  }
});

exports.processJobOnCreate = onDocumentCreated(
  { document: "job_queue/{jobId}", region: FUNCTIONS_REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.status !== "pending") return;
    if (data.priority !== "high") return;

    const db = getFirestore();
    const fakeDoc = { id: event.params.jobId };
    try {
      const claimed = await claimJob(db, fakeDoc);
      if (claimed) await processJob(db, claimed);
    } catch (err) {
      logger.error("high priority job failed", {
        jobId: event.params.jobId,
        error: String(err),
      });
      await failJob(db, event.params.jobId, err);
    }
  },
);

module.exports.drainQueue = drainQueue;
module.exports.processJob = processJob;
module.exports.claimJob = claimJob;
