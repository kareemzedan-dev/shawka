const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  assertDeliveryDriver,
} = require("../shared/permissions");
const { acceptOffer, rejectOffer } = require("./offerManager");

const respondToOffer = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const db = getFirestore();
    const uid = auth.uid;

    await checkRateLimit(db, `respondOffer:${uid}`, 30, 60 * 1000);

    const orderId =
      typeof request.data?.orderId === "string" ? request.data.orderId : "";
    const action =
      typeof request.data?.action === "string" ? request.data.action : "";
    const operationId =
      typeof request.data?.operationId === "string"
        ? request.data.operationId
        : "";

    if (!orderId || !operationId) {
      throw new HttpsError("invalid-argument", "orderId و operationId مطلوبان.");
    }
    if (action !== "accept" && action !== "reject") {
      throw new HttpsError("invalid-argument", "action يجب accept أو reject.");
    }

    const driverSnap = await db.collection("users").doc(uid).get();
    assertDeliveryDriver(auth.token, driverSnap.exists ? driverSnap.data() : {});

    if (action === "accept") {
      const result = await acceptOffer(db, {
        orderId,
        driverId: uid,
        operationId,
      });
      return { ...result, event: "order_offer_accepted" };
    }

    const result = await rejectOffer(db, {
      orderId,
      driverId: uid,
      reason: "driver_rejected",
    });
    return { ...result, event: "order_offer_rejected" };
  },
);

module.exports = { respondToOffer };
