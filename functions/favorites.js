const crypto = require("node:crypto");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("./shared/region");

function eventMarkerId(eventId) {
  return crypto.createHash("sha256").update(eventId).digest("hex");
}

function favoriteTargets(favorite) {
  if (!favorite || typeof favorite.storeId !== "string") return [];
  const targets = [{
    path: `stores/${favorite.storeId}`,
    field: "totalFavorites",
  }];
  if (
    favorite.type === "product" &&
    typeof favorite.productId === "string" &&
    favorite.productId
  ) {
    targets.push({
      path: `stores/${favorite.storeId}/products/${favorite.productId}`,
      field: "favoritesCount",
    });
  }
  return targets;
}

function collectDeltas(before, after) {
  const deltas = new Map();
  for (const target of favoriteTargets(before)) {
    deltas.set(target.path, { ...target, delta: -1 });
  }
  for (const target of favoriteTargets(after)) {
    const current = deltas.get(target.path);
    deltas.set(target.path, {
      ...target,
      delta: (current?.delta || 0) + 1,
    });
  }
  return [...deltas.values()].filter((target) => target.delta !== 0);
}

const onFavoriteWrite = onDocumentWritten(
  {
    document: "users/{uid}/favorites/{favoriteId}",
    region: FUNCTIONS_REGION,
  },
  async (event) => {
    const before = event.data?.before.exists
      ? event.data.before.data()
      : null;
    const after = event.data?.after.exists
      ? event.data.after.data()
      : null;
    const deltas = collectDeltas(before, after);
    if (deltas.length === 0) return;

    const db = getFirestore();
    const marker = db.collection("_function_events")
      .doc(`favorite_${eventMarkerId(event.id)}`);
    try {
      await db.runTransaction(async (transaction) => {
        const markerSnapshot = await transaction.get(marker);
        if (markerSnapshot.exists) return;

        const refs = deltas.map((target) => db.doc(target.path));
        const snapshots = await Promise.all(
          refs.map((ref) => transaction.get(ref)),
        );
        snapshots.forEach((snapshot, index) => {
          if (!snapshot.exists) return;
          const target = deltas[index];
          transaction.update(snapshot.ref, {
            [target.field]: FieldValue.increment(target.delta),
          });
        });
        transaction.set(marker, {
          type: "favorite",
          processedAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      logger.error("favorite_aggregation_failed", {
        eventId: event.id,
        uid: event.params.uid,
        favoriteId: event.params.favoriteId,
        error: String(error),
      });
      throw error;
    }
  },
);

module.exports = { onFavoriteWrite, collectDeltas };
