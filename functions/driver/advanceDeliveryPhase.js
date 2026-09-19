const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue, GeoPoint } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  assertDeliveryDriver,
} = require("../shared/permissions");
const { clearActiveOrderLock } = require("../assignment/offerManager");
const { isWithinRadiusMeters } = require("../shared/geoDistance");
const { encodeGeohash } = require("../shared/geohash");
const { logOpsIncident } = require("../shared/opsIncidents");
const { refreshDriverScore } = require("./driverPerformanceScore");
const { applyDeliveryWalletCredits } = require("../shared/driverWallet");

const VALID_PHASES = new Set([
  "accepted",
  "picked_up",
  "in_transit",
  "delivered",
]);

const PICKUP_RADIUS_M = 800;
const DELIVERY_RADIUS_M = 800;

async function resolveStoreCoords(db, order) {
  if (typeof order.storeLat === "number" && typeof order.storeLng === "number") {
    return { lat: order.storeLat, lng: order.storeLng };
  }
  const storeId = order.storeId;
  if (typeof storeId === "string" && storeId.length > 0) {
    const storeSnap = await db.collection("stores").doc(storeId).get();
    if (storeSnap.exists) {
      const s = storeSnap.data();
      if (typeof s.latitude === "number" && typeof s.longitude === "number") {
        return { lat: s.latitude, lng: s.longitude };
      }
    }
  }
  return null;
}

function readDriverCoords(driver) {
  const lat = typeof driver.latitude === "number" ? driver.latitude : null;
  const lng = typeof driver.longitude === "number" ? driver.longitude : null;
  if (lat == null || lng == null) return null;
  return { lat, lng };
}

function readClientCoords(data) {
  const lat = data?.latitude;
  const lng = data?.longitude;
  if (typeof lat !== "number" || typeof lng !== "number") return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return { lat, lng };
}

async function persistDriverCoords(db, uid, coords) {
  await db.collection("users").doc(uid).update({
    latitude: coords.lat,
    longitude: coords.lng,
    location: new GeoPoint(coords.lat, coords.lng),
    geohash: encodeGeohash(coords.lat, coords.lng),
    locationUpdatedAt: FieldValue.serverTimestamp(),
    geohashUpdatedAt: FieldValue.serverTimestamp(),
    lastActiveAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function resolveDriverCoords(db, uid, driver, clientCoords) {
  if (clientCoords) {
    await persistDriverCoords(db, uid, clientCoords);
    return clientCoords;
  }
  return readDriverCoords(driver);
}

async function executeAdvanceDeliveryPhase(
  db,
  { orderId, uid, token, phase, clientCoords = null },
) {
  if (!VALID_PHASES.has(phase)) {
    throw new HttpsError("invalid-argument", "phase غير صالح.");
  }

  const driverSnap = await db.collection("users").doc(uid).get();
  assertDeliveryDriver(token, driverSnap.exists ? driverSnap.data() : {});

  const driver = driverSnap.data();
  const driverCoords = await resolveDriverCoords(
    db,
    uid,
    driver,
    clientCoords,
  );

  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    throw new HttpsError("not-found", "الطلب غير موجود.");
  }
  const order = orderSnap.data();

  if (order.deliveryId !== uid) {
    throw new HttpsError("permission-denied", "ليس مندوب هذا الطلب.");
  }

  if (phase === "picked_up") {
    if (!driverCoords) {
      throw new HttpsError("failed-precondition", "GPS مطلوب لتأكيد الاستلام.");
    }
    const storeCoords = await resolveStoreCoords(db, order);
    if (storeCoords) {
      const ok = isWithinRadiusMeters(
        driverCoords.lat,
        driverCoords.lng,
        storeCoords.lat,
        storeCoords.lng,
        PICKUP_RADIUS_M,
      );
      if (!ok) {
        await logOpsIncident(db, {
          type: "gps_fraud_pickup",
          severity: "critical",
          message: "محاولة استلام بعيدة عن المتجر",
          orderId,
          driverId: uid,
        });
        throw new HttpsError(
          "failed-precondition",
          "يجب أن تكون عند المتجر لتأكيد الاستلام.",
        );
      }
    }
  }

  if (phase === "delivered") {
    if (!driverCoords) {
      throw new HttpsError("failed-precondition", "GPS مطلوب لتأكيد التسليم.");
    }
    const cLat = order.addressLat;
    const cLng = order.addressLng;
    if (typeof cLat === "number" && typeof cLng === "number") {
      const ok = isWithinRadiusMeters(
        driverCoords.lat,
        driverCoords.lng,
        cLat,
        cLng,
        DELIVERY_RADIUS_M,
      );
      if (!ok) {
        await logOpsIncident(db, {
          type: "gps_fraud_delivered",
          severity: "critical",
          message: "محاولة تسليم بعيدة عن العميل",
          orderId,
          driverId: uid,
        });
        throw new HttpsError(
          "failed-precondition",
          "يجب أن تكون عند العميل لتأكيد التسليم.",
        );
      }
    }
  }

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(orderRef);
    if (!freshSnap.exists) {
      throw new Error("ORDER_NOT_FOUND");
    }
    const fresh = freshSnap.data();
    if (fresh.deliveryId !== uid) {
      throw new Error("NOT_DRIVER");
    }

    const update = {
      deliveryPhase: phase,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (phase === "picked_up") {
      update.deliveryPickedUpAt = FieldValue.serverTimestamp();
      update.status = "outForDelivery";
    } else if (phase === "in_transit") {
      update.status = "outForDelivery";
    } else if (phase === "delivered") {
      update.deliveryDeliveredAt = FieldValue.serverTimestamp();
      update.status = "delivered";
      update.assignmentStatus = "completed";
    }

    tx.update(orderRef, update);
  });

  if (phase === "delivered") {
    const freshOrderSnap = await orderRef.get();
    const freshOrder = freshOrderSnap.data() || order;

    await clearActiveOrderLock(db, {
      driverId: uid,
      orderId,
      actorUid: uid,
      reason: "delivered",
    });
    try {
      const driverRef = db.collection("users").doc(uid);
      const dSnap = await driverRef.get();
      const prev = dSnap.data()?.completedOrderCount || 0;
      await driverRef.update({
        completedOrderCount: prev + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
      await refreshDriverScore(db, uid);
    } catch (e) {
      // non-blocking
    }
    try {
      await applyDeliveryWalletCredits(db, {
        driverId: uid,
        orderId,
        order: freshOrder,
      });
    } catch (e) {
      // non-blocking — delivery already completed
    }
    return { ok: true, orderId, phase, event: "delivery_completed" };
  }

  if (phase === "picked_up") {
    return { ok: true, orderId, phase, event: "delivery_started" };
  }

  return { ok: true, orderId, phase };
}

const advanceDeliveryPhase = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const db = getFirestore();
    const uid = auth.uid;

    await checkRateLimit(db, `advancePhase:${uid}`, 60, 60 * 1000);

    const orderId =
      typeof request.data?.orderId === "string" ? request.data.orderId : "";
    const phase =
      typeof request.data?.phase === "string" ? request.data.phase : "";

    if (!orderId || !phase) {
      throw new HttpsError("invalid-argument", "orderId و phase مطلوبان.");
    }

    return executeAdvanceDeliveryPhase(db, {
      orderId,
      uid,
      token: auth.token,
      phase,
      clientCoords: readClientCoords(request.data),
    });
  },
);

module.exports = { advanceDeliveryPhase, executeAdvanceDeliveryPhase };
