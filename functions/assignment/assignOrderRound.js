const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { checkRateLimit } = require("../rateLimit");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  canManageOrders,
  assertAuthenticated,
} = require("../shared/permissions");
const { runAssignOrderRound } = require("./assignOrderRoundCore");

const assignOrderRound = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const db = getFirestore();

    if (!canManageOrders(auth.token)) {
      throw new HttpsError("permission-denied", "Staff only.");
    }

    await checkRateLimit(db, `assignRound:${auth.uid}`, 60, 60 * 1000);

    const orderId =
      typeof request.data?.orderId === "string" ? request.data.orderId : "";
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId مطلوب.");
    }

    const round =
      typeof request.data?.round === "number" ? request.data.round : undefined;
    const operationId =
      typeof request.data?.operationId === "string"
        ? request.data.operationId
        : undefined;

    return runAssignOrderRound(db, { orderId, round, operationId });
  },
);

module.exports = { assignOrderRound, runAssignOrderRound };
