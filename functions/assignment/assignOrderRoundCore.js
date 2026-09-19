const { HttpsError } = require("firebase-functions/v2/https");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { getRuntimeConfig, getConfig } = require("../shared/config");
const { neighboursForRound } = require("../shared/geohash");
const { isAssignmentEligible, hasActiveOrderLock, isDriverApproved } = require("./eligibility");
const { rankDrivers, pickNextDriver } = require("./ranking");
const { enqueueAssignRoundJob, generateOperationId } = require("./offerManager");
const { applyOfferReceivedTx } = require("../shared/driverOfferStats");
const { logOpsIncident } = require("../shared/opsIncidents");
const { isReadyForDriverAssignment } = require("../shared/orderStatusFlow");

async function resolveStoreCoords(db, order) {
  if (typeof order.storeLat === "number" && typeof order.storeLng === "number") {
    return { lat: order.storeLat, lng: order.storeLng };
  }

  const storeId = order.storeId;
  if (typeof storeId === "string" && storeId.length > 0) {
    const storeSnap = await db.collection("stores").doc(storeId).get();
    if (storeSnap.exists) {
      const store = storeSnap.data();
      const lat = store.latitude ?? store.lat;
      const lng = store.longitude ?? store.lng;
      if (typeof lat === "number" && typeof lng === "number") {
        return { lat, lng };
      }
    }
  }

  const gov = order.governorate;
  if (typeof gov === "string" && gov.length > 0) {
    const govSnap = await db
      .collection("governorates")
      .where("name", "==", gov)
      .limit(1)
      .get();
    if (!govSnap.empty) {
      const g = govSnap.docs[0].data();
      if (typeof g.latitude === "number" && typeof g.longitude === "number") {
        return { lat: g.latitude, lng: g.longitude };
      }
    }
  }

  logger.warn("assignOrderRound: missing store coords, using fallback", {
    orderId: order.id,
    governorate: order.governorate,
  });
  return { lat: 30.0444, lng: 31.2357 };
}

async function collectEligibleDrivers(db, docs, seen, drivers, orderContext) {
  for (const doc of docs) {
    if (seen.has(doc.id)) continue;
    seen.add(doc.id);

    const data = doc.data();
    if (!isDriverApproved(data)) continue;
    if (hasActiveOrderLock(data)) continue;

    const eligibility = isAssignmentEligible(
      { ...data, id: doc.id },
      Date.now(),
      undefined,
      orderContext,
    );
    if (!eligibility.eligible) {
      logger.info("assignOrderRound: driver_ineligible", {
        orderId: orderContext?.orderId,
        driverId: doc.id,
        reason: eligibility.reason,
        governorate: data.governorate,
        isDriverOnline: data.isDriverOnline,
        driverApprovalStatus: data.driverApprovalStatus,
      });
      continue;
    }

    drivers.push({
      id: doc.id,
      ...data,
      _coords: eligibility.coords,
    });
  }
}

async function fetchOnlineDriversFallback(db, order, config, seen, drivers, orderContext) {
  const cfg = config || getConfig();
  let query = db
    .collection("users")
    .where("role", "==", "delivery")
    .where("isDriverOnline", "==", true);

  const governorate = order.governorate;
  if (typeof governorate === "string" && governorate.length > 0) {
    query = query.where("governorate", "==", governorate);
  }

  const snap = await query.limit(cfg.driver_assignment_candidates_per_round).get();
  await collectEligibleDrivers(db, snap.docs, seen, drivers, orderContext);

  if (drivers.length > 0) return drivers;

  const broadSnap = await db
    .collection("users")
    .where("role", "==", "delivery")
    .where("isDriverOnline", "==", true)
    .limit(cfg.driver_assignment_candidates_per_round)
    .get();
  await collectEligibleDrivers(db, broadSnap.docs, seen, drivers, orderContext);
  return drivers;
}

async function fetchCandidateDrivers(db, order, storeCoords, round, config) {
  const cfg = config || getConfig();
  const orderContext = {
    orderId: order.id,
    governorate: order.governorate,
    storeLat: storeCoords.lat,
    storeLng: storeCoords.lng,
  };
  const geohashes = neighboursForRound(storeCoords.lat, storeCoords.lng, round);
  const seen = new Set();
  const drivers = [];

  for (const hash of geohashes) {
    try {
      const query = db
        .collection("users")
        .where("role", "==", "delivery")
        .where("isDriverOnline", "==", true)
        .where("geohash", ">=", hash)
        .where("geohash", "<=", `${hash}\uf8ff`);

      const snap = await query.limit(cfg.driver_assignment_candidates_per_round).get();
      await collectEligibleDrivers(db, snap.docs, seen, drivers, orderContext);
    } catch (err) {
      logger.warn("assignOrderRound: geohash_query_failed", {
        orderId: order.id,
        geohash: hash,
        error: String(err),
      });
    }
  }

  if (drivers.length === 0) {
    await fetchOnlineDriversFallback(db, order, cfg, seen, drivers, orderContext);
  }

  return drivers;
}

/**
 * Core assignOrderRound logic — callable + job_queue.
 */
async function runAssignOrderRound(db, { orderId, round, operationId, config }) {
  const cfg = config || await getRuntimeConfig();
  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();

  if (!orderSnap.exists) {
    throw new HttpsError("not-found", "NOT_FOUND");
  }

  const order = { id: orderSnap.id, ...orderSnap.data() };

  if (order.status === "cancelled" || order.deliveryPhase === "cancelled") {
    return { skipped: true, reason: "cancelled" };
  }
  if (!isReadyForDriverAssignment(order.status)) {
    return { skipped: true, reason: "not_ready_for_pickup" };
  }
  if (order.deliveryId) {
    return { skipped: true, reason: "already_assigned" };
  }
  if (order.assignmentStatus === "accepted") {
    return { skipped: true, reason: "already_accepted" };
  }

  let currentRound = round || order.assignmentRound || 1;

  if (
    order.assignmentStatus === "failed" &&
    !order.deliveryId &&
    round == null
  ) {
    currentRound = 1;
    await orderRef.update({
      assignmentStatus: "searching",
      assignmentRound: 1,
      deliveryPhase: "unassigned",
      rejectedDriverIds: [],
      deliveryRejectReason: FieldValue.delete(),
      candidateDriverIds: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  if (currentRound > cfg.driver_assignment_max_rounds) {
    await orderRef.update({
      assignmentStatus: "failed",
      deliveryPhase: "unassigned",
      updatedAt: FieldValue.serverTimestamp(),
    });
    await logOpsIncident(db, {
      type: "assignment_exhausted",
      severity: "critical",
      message: `فشل تخصيص الطلب ${orderId} — استنفاد الجولات`,
      orderId,
      details: { round: currentRound },
    });
    throw new HttpsError("failed-precondition", "ASSIGNMENT_EXHAUSTED");
  }

  const storeCoords = await resolveStoreCoords(db, order);
  if (typeof order.storeLat !== "number") {
    await orderRef.set(
      { storeLat: storeCoords.lat, storeLng: storeCoords.lng },
      { merge: true },
    );
  }

  const rejected = Array.isArray(order.rejectedDriverIds) ? order.rejectedDriverIds : [];
  const candidates = await fetchCandidateDrivers(db, order, storeCoords, currentRound, cfg);
  if (candidates.length === 0) {
    logger.warn("assignOrderRound: no eligible drivers", {
      orderId: order.id,
      governorate: order.governorate,
      round: currentRound,
      storeLat: storeCoords.lat,
      storeLng: storeCoords.lng,
    });
  }
  const ranked = rankDrivers(
    candidates,
    storeCoords.lat,
    storeCoords.lng,
    cfg,
    currentRound,
  );
  const topK = ranked.slice(0, cfg.driver_assignment_candidates_per_round);
  const next = pickNextDriver(topK, rejected, {
    allowRejectedWhenExhausted: candidates.length <= 1,
  });

  if (!next) {
    const nextRound = currentRound + 1;
    if (nextRound > cfg.driver_assignment_max_rounds) {
      await orderRef.update({
        assignmentStatus: "failed",
        deliveryPhase: "unassigned",
        updatedAt: FieldValue.serverTimestamp(),
      });
      await logOpsIncident(db, {
        type: "assignment_exhausted",
        severity: "critical",
        message: `فشل تخصيص الطلب ${orderId} — لا مندوبين متاحين`,
        orderId,
        details: { round: nextRound },
      });
      throw new HttpsError("failed-precondition", "ASSIGNMENT_EXHAUSTED");
    }

    await orderRef.update({
      assignmentRound: nextRound,
      assignmentStatus: "searching",
      updatedAt: FieldValue.serverTimestamp(),
    });
    await enqueueAssignRoundJob(db, orderId, nextRound);
    return { ok: true, exhaustedRound: true, nextRound };
  }

  const opId = operationId || generateOperationId();
  const deadlineMs = Date.now() + cfg.driver_assignment_accept_seconds * 1000;
  const deadline = Timestamp.fromMillis(deadlineMs);
  const candidateIds = topK.map((e) => e.id);

  const offerResult = await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(orderRef);
    if (!freshSnap.exists) {
      throw new HttpsError("not-found", "NOT_FOUND");
    }
    const fresh = freshSnap.data();

    if (fresh.deliveryId) {
      return { skipped: true, reason: "assigned_during_tx" };
    }

    const phase = fresh.deliveryPhase;
    const status = fresh.assignmentStatus;
    if (
      phase === "offered" &&
      fresh.offeredDriverId &&
      !isDeadlinePassedLocal(fresh.deliveryAcceptDeadline)
    ) {
      return { skipped: true, reason: "offer_pending" };
    }

    if (
      status !== "searching" &&
      status !== "offering" &&
      phase !== "unassigned" &&
      phase !== "searching"
    ) {
      if (status !== "searching" && phase !== "unassigned") {
        throw new HttpsError("failed-precondition", "FAILED_PRECONDITION");
      }
    }

    const driverRef = db.collection("users").doc(next.id);
    const driverSnap = await tx.get(driverRef);
    if (!driverSnap.exists) {
      throw new HttpsError("failed-precondition", "DRIVER_NOT_ELIGIBLE");
    }
    const driver = driverSnap.data();
    const eligibility = isAssignmentEligible(driver, Date.now(), cfg, {
      orderId,
      governorate: fresh.governorate,
      storeLat: storeCoords.lat,
      storeLng: storeCoords.lng,
    });
    if (!eligibility.eligible || hasActiveOrderLock(driver)) {
      throw new HttpsError("failed-precondition", "DRIVER_NOT_ELIGIBLE");
    }

    tx.update(orderRef, {
      candidateDriverIds: candidateIds,
      offeredDriverId: next.id,
      deliveryPhase: "offered",
      assignmentStatus: "offering",
      assignmentRound: currentRound,
      deliveryAcceptDeadline: deadline,
      offeredAt: FieldValue.serverTimestamp(),
      assignmentOperationId: opId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(driverRef, {
      lastOfferedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    applyOfferReceivedTx(tx, driverRef, driver);

    return {
      ok: true,
      orderId,
      offeredDriverId: next.id,
      round: currentRound,
      deadlineMs,
      distanceKm: next.distanceKm,
    };
  });

  return offerResult;
}

function isDeadlinePassedLocal(deadline) {
  if (!deadline) return true;
  const ms =
    typeof deadline.toMillis === "function"
      ? deadline.toMillis()
      : deadline instanceof Date
        ? deadline.getTime()
        : null;
  return ms == null || ms <= Date.now();
}

module.exports = {
  resolveStoreCoords,
  fetchCandidateDrivers,
  runAssignOrderRound,
};
