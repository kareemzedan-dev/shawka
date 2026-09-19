const { FieldValue } = require("firebase-admin/firestore");

function computeAcceptRate(accepted, received) {
  if (received <= 0) return 0.5;
  return Math.min(1, Math.max(0, accepted / received));
}

/** Transaction-safe: driver received a new offer. */
function applyOfferReceivedTx(tx, driverRef, driver) {
  const received = (typeof driver.driverOffersReceived === "number"
    ? driver.driverOffersReceived
    : 0) + 1;
  const accepted =
    typeof driver.driverOffersAccepted === "number"
      ? driver.driverOffersAccepted
      : 0;
  tx.update(driverRef, {
    driverOffersReceived: received,
    acceptRate: computeAcceptRate(accepted, received),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

/** Transaction-safe: driver accepted an offer. */
function applyOfferAcceptedTx(tx, driverRef, driver) {
  const received = Math.max(
    1,
    typeof driver.driverOffersReceived === "number"
      ? driver.driverOffersReceived
      : 0,
  );
  const accepted =
    (typeof driver.driverOffersAccepted === "number"
      ? driver.driverOffersAccepted
      : 0) + 1;
  tx.update(driverRef, {
    driverOffersReceived: received,
    driverOffersAccepted: accepted,
    acceptRate: computeAcceptRate(accepted, received),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

module.exports = {
  computeAcceptRate,
  applyOfferReceivedTx,
  applyOfferAcceptedTx,
};
