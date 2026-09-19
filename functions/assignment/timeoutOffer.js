const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");
const { FUNCTIONS_REGION } = require("../shared/region");
const { timeoutOfferForOrder } = require("./offerManager");

const timeoutOffer = onSchedule(
  { schedule: "every 1 minutes", region: FUNCTIONS_REGION },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();

    const snap = await db
      .collection("orders")
      .where("deliveryPhase", "==", "offered")
      .where("deliveryAcceptDeadline", "<", now)
      .limit(100)
      .get();

    if (snap.empty) {
      logger.info("timeoutOffer: no expired offers");
      return;
    }

    let processed = 0;
    for (const doc of snap.docs) {
      try {
        const result = await timeoutOfferForOrder(db, doc.id);
        if (result.ok) {
          processed += 1;
          logger.info("order_offer_timeout", { orderId: doc.id });
        }
      } catch (err) {
        logger.error("timeoutOffer failed", {
          orderId: doc.id,
          error: String(err),
        });
      }
    }

    if (processed > 0) {
      logger.info("timeoutOffer batch complete", { processed });
    }
  },
);

module.exports = { timeoutOffer };
