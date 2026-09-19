const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { FieldValue } = require("firebase-admin/firestore");
const { getFirestore } = require("firebase-admin/firestore");
const { FUNCTIONS_REGION } = require("../shared/region");
const {
  assertAuthenticated,
  canManageDeliveryUsers,
} = require("../shared/permissions");
const { applyWalletSettlement } = require("../shared/driverWallet");

const SETTLEMENT_METHODS = new Set([
  "bank_transfer",
  "vodafone_cash",
  "instapay",
  "cash_deposit",
]);

const METHOD_LABELS = {
  bank_transfer: "تحويل بنكي",
  vodafone_cash: "فودافون كاش",
  instapay: "Instapay",
  cash_deposit: "إيداع نقدي",
};

/**
 * Driver submits a settlement request for admin review.
 */
const submitSettlementRequest = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    const db = getFirestore();

    const driverSnap = await db.collection("users").doc(auth.uid).get();
    if (!driverSnap.exists || driverSnap.data()?.role !== "delivery") {
      throw new HttpsError("permission-denied", "للمندوبين فقط.");
    }

    const amount = request.data?.amount;
    const method =
      typeof request.data?.method === "string"
        ? request.data.method.trim()
        : "";
    const transactionReference =
      typeof request.data?.transactionReference === "string"
        ? request.data.transactionReference.trim()
        : "";
    const notes =
      typeof request.data?.notes === "string"
        ? request.data.notes.trim().slice(0, 500)
        : "";
    const receiptImageUrl =
      typeof request.data?.receiptImageUrl === "string"
        ? request.data.receiptImageUrl.trim()
        : "";

    if (typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("invalid-argument", "المبلغ غير صالح.");
    }
    if (!SETTLEMENT_METHODS.has(method)) {
      throw new HttpsError("invalid-argument", "طريقة السداد غير صالحة.");
    }

    const driver = driverSnap.data();
    const outstanding =
      typeof driver.outstandingBalance === "number"
        ? driver.outstandingBalance
        : 0;
    if (amount > outstanding + 0.01) {
      throw new HttpsError(
        "failed-precondition",
        "المبلغ يتجاوز المستحق الحالي.",
      );
    }

    const pendingSnap = await db
      .collection("settlement_requests")
      .where("driverId", "==", auth.uid)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    if (!pendingSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "لديك طلب تسوية قيد المراجعة بالفعل.",
      );
    }

    const docRef = await db.collection("settlement_requests").add({
      driverId: auth.uid,
      driverName: typeof driver.name === "string" ? driver.name : "",
      amount: Math.round(amount * 100) / 100,
      method,
      methodLabel: METHOD_LABELS[method] || method,
      transactionReference: transactionReference || null,
      notes: notes || null,
      receiptImageUrl: receiptImageUrl || null,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      reviewedAt: null,
      reviewedBy: null,
      reviewReason: null,
    });

    return { ok: true, requestId: docRef.id };
  },
);

/**
 * Admin approves or rejects a settlement request.
 */
const reviewSettlementRequest = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const auth = assertAuthenticated(request);
    if (!canManageDeliveryUsers(auth.token)) {
      throw new HttpsError("permission-denied", "غير مصرح.");
    }

    const requestId =
      typeof request.data?.requestId === "string"
        ? request.data.requestId.trim()
        : "";
    const action =
      typeof request.data?.action === "string"
        ? request.data.action.trim()
        : "";
    const reviewReason =
      typeof request.data?.reviewReason === "string"
        ? request.data.reviewReason.trim().slice(0, 500)
        : "";
    const approvedAmount = request.data?.amount;

    if (!requestId) {
      throw new HttpsError("invalid-argument", "requestId مطلوب.");
    }
    if (action !== "approve" && action !== "reject") {
      throw new HttpsError("invalid-argument", "إجراء غير صالح.");
    }

    const db = getFirestore();
    const reqRef = db.collection("settlement_requests").doc(requestId);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "الطلب غير موجود.");
    }

    const reqData = reqSnap.data();
    if (reqData.status !== "pending") {
      throw new HttpsError("failed-precondition", "تمت مراجعة الطلب مسبقاً.");
    }

    if (action === "reject") {
      if (!reviewReason) {
        throw new HttpsError("invalid-argument", "سبب الرفض مطلوب.");
      }
      await reqRef.update({
        status: "rejected",
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: auth.uid,
        reviewReason,
      });
      return { ok: true, status: "rejected" };
    }

    const amount =
      typeof approvedAmount === "number" && approvedAmount > 0
        ? approvedAmount
        : reqData.amount;

    const notes = [
      reqData.methodLabel || reqData.method,
      reqData.transactionReference
        ? `مرجع: ${reqData.transactionReference}`
        : null,
      reqData.notes,
    ]
      .filter(Boolean)
      .join(" · ");

    await applyWalletSettlement(db, {
      driverId: reqData.driverId,
      amount,
      notes: notes || "تسوية من طلب المندوب",
      createdBy: auth.uid,
      source: "driver_request",
      referenceId: requestId,
      performedByRole: "staff",
    });

    await reqRef.update({
      status: "approved",
      amount,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewedBy: auth.uid,
      reviewReason: reviewReason || null,
    });

    return { ok: true, status: "approved", amount };
  },
);

module.exports = { submitSettlementRequest, reviewSettlementRequest };
