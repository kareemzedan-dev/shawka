const crypto = require("node:crypto");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("./shared/region");
const {
  approvedContribution,
  applyAggregateDelta,
} = require("./reviewsCore");

function eventMarkerId(eventId) {
  return crypto.createHash("sha256").update(eventId).digest("hex");
}

function reviewTargets(review) {
  if (!review || typeof review.storeId !== "string" || !review.storeId) {
    return [];
  }
  const targets = [`stores/${review.storeId}`];
  if (typeof review.productId === "string" && review.productId) {
    targets.push(`stores/${review.storeId}/products/${review.productId}`);
  }
  return targets;
}

function collectReviewDeltas(before, after) {
  const deltas = new Map();
  const previous = approvedContribution(before);
  const next = approvedContribution(after);

  for (const path of reviewTargets(before)) {
    deltas.set(path, {
      countDelta: -previous.count,
      sumDelta: -previous.sum,
    });
  }
  for (const path of reviewTargets(after)) {
    const current = deltas.get(path) || { countDelta: 0, sumDelta: 0 };
    deltas.set(path, {
      countDelta: current.countDelta + next.count,
      sumDelta: current.sumDelta + next.sum,
    });
  }
  return [...deltas.entries()]
    .filter(([, delta]) => delta.countDelta !== 0 || delta.sumDelta !== 0)
    .map(([path, delta]) => ({ path, ...delta }));
}

const onReviewWrite = onDocumentWritten(
  { document: "reviews/{reviewId}", region: FUNCTIONS_REGION },
  async (event) => {
    const before = event.data?.before.exists
      ? event.data.before.data()
      : null;
    const after = event.data?.after.exists
      ? event.data.after.data()
      : null;
    const deltas = collectReviewDeltas(before, after);
    if (deltas.length === 0) return;

    const db = getFirestore();
    const marker = db.collection("_function_events")
      .doc(`review_${eventMarkerId(event.id)}`);
    try {
      await db.runTransaction(async (transaction) => {
        const markerSnapshot = await transaction.get(marker);
        if (markerSnapshot.exists) return;

        const refs = deltas.map((delta) => db.doc(delta.path));
        const snapshots = await Promise.all(
          refs.map((ref) => transaction.get(ref)),
        );
        snapshots.forEach((snapshot, index) => {
          if (!snapshot.exists) return;
          const data = snapshot.data();
          const reviewCount = Number(data.reviewCount || 0);
          const ratingSum = data.ratingSum == null
            ? Number(data.rating || 0) * reviewCount
            : Number(data.ratingSum);
          const aggregate = applyAggregateDelta(
            reviewCount,
            ratingSum,
            deltas[index],
          );
          transaction.set(snapshot.ref, aggregate, { merge: true });
        });
        transaction.set(marker, {
          type: "review",
          processedAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      logger.error("review_aggregation_failed", {
        eventId: event.id,
        reviewId: event.params.reviewId,
        error: String(error),
      });
      throw error;
    }
  },
);

const toggleReviewHelpful = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const reviewId = request.data?.reviewId;
    if (typeof reviewId !== "string" || !reviewId || reviewId.length > 256) {
      throw new HttpsError("invalid-argument", "A valid reviewId is required.");
    }

    const db = getFirestore();
    const reviewRef = db.collection("reviews").doc(reviewId);
    const likeRef = reviewRef.collection("likes").doc(request.auth.uid);
    let result;
    await db.runTransaction(async (transaction) => {
      const [reviewSnapshot, likeSnapshot] = await Promise.all([
        transaction.get(reviewRef),
        transaction.get(likeRef),
      ]);
      if (!reviewSnapshot.exists) {
        throw new HttpsError("not-found", "Review not found.");
      }

      const current = Number(reviewSnapshot.data().helpfulCount || 0);
      if (likeSnapshot.exists) {
        const helpfulCount = Math.max(0, current - 1);
        transaction.delete(likeRef);
        transaction.update(reviewRef, { helpfulCount });
        result = { helpful: false, helpfulCount };
      } else {
        const helpfulCount = current + 1;
        transaction.create(likeRef, {
          createdAt: FieldValue.serverTimestamp(),
        });
        transaction.update(reviewRef, { helpfulCount });
        result = { helpful: true, helpfulCount };
      }
    });
    return result;
  },
);

module.exports = {
  onReviewWrite,
  toggleReviewHelpful,
  collectReviewDeltas,
};
