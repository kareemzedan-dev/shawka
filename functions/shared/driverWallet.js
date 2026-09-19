const { FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");
const { trackAnalyticsEventInternal } = require("./analyticsInternal");
const {
  loadWalletThresholds,
  computeWalletStatus,
  isDriverCashBlocked,
} = require("./walletThresholds");

const TX_COLLECTION = "wallet_transactions";

const LEGACY_TYPE_MAP = Object.freeze({
  delivery_earnings: "earning",
  cod_collection: "cod_collection",
  delivery_completed: "earning",
  settlement: "settlement",
  bonus: "bonus",
  penalty: "penalty",
  adjustment: "manual_adjustment",
  manual_adjustment: "manual_adjustment",
  correction: "correction",
  refund: "refund",
});

function roundMoney(value) {
  return Math.round((value || 0) * 100) / 100;
}

function mapTransactionType(legacyType) {
  if (typeof legacyType !== "string") return "manual_adjustment";
  return LEGACY_TYPE_MAP[legacyType] || legacyType;
}

function isCodPayment(method) {
  const m = typeof method === "string" ? method.toLowerCase() : "cash";
  return m === "cash" || m === "cash_on_delivery" || m === "cod";
}

function orderPayableTotal(order) {
  const total = typeof order.total === "number" ? order.total : 0;
  const deliveryFee =
    typeof order.deliveryFee === "number" ? order.deliveryFee : 0;
  const discount =
    typeof order.discountAmount === "number" ? order.discountAmount : 0;
  return roundMoney(Math.max(0, total + deliveryFee - discount));
}

function readWalletFields(user) {
  const earnings =
    typeof user.earningsBalance === "number" ? user.earningsBalance : 0;
  const outstanding =
    typeof user.outstandingBalance === "number" ? user.outstandingBalance : 0;
  const net =
    typeof user.netBalance === "number"
      ? user.netBalance
      : roundMoney(earnings - outstanding);
  return {
    earningsBalance: roundMoney(earnings),
    outstandingBalance: roundMoney(outstanding),
    netBalance: roundMoney(net),
    driverCashBlocked: user.driverCashBlocked === true,
    walletStatus:
      typeof user.walletStatus === "string" ? user.walletStatus : "regular",
    walletLastNotifiedLevel:
      typeof user.walletLastNotifiedLevel === "string"
        ? user.walletLastNotifiedLevel
        : null,
    walletDueNotifiedAt:
      user.walletDueNotifiedAt && typeof user.walletDueNotifiedAt.toDate === "function"
        ? user.walletDueNotifiedAt.toDate()
        : null,
    fcmToken:
      typeof user.fcmToken === "string" && user.fcmToken.length > 10
        ? user.fcmToken
        : null,
    name: typeof user.name === "string" ? user.name : "",
  };
}

function writeWalletTransaction(tx, db, entry) {
  const ref = db.collection(TX_COLLECTION).doc(entry.id);
  const legacyType = entry.type;
  const transactionType =
    entry.transactionType || mapTransactionType(legacyType);
  const performedBy = entry.performedBy || entry.createdBy || "system";
  const performedByRole = entry.performedByRole || "system";
  const source = entry.source || "cloud_function";

  tx.set(ref, {
    driverId: entry.driverId,
    type: legacyType,
    transactionType,
    amount: entry.amount,
    balanceBefore: entry.balanceBefore,
    balanceAfter: entry.balanceAfter,
    earningsBalanceBefore: entry.earningsBalanceBefore,
    earningsBalanceAfter: entry.earningsBalanceAfter,
    outstandingBalanceBefore: entry.outstandingBalanceBefore,
    outstandingBalanceAfter: entry.outstandingBalanceAfter,
    orderId: entry.orderId || null,
    notes: entry.notes || null,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: performedBy,
    performedBy,
    performedByRole,
    performedAt: FieldValue.serverTimestamp(),
    source,
    referenceId: entry.referenceId || null,
  });
}

async function sendWalletPush({ token, title, body, type, route }) {
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data: {
        type,
        route: route || "/wallet",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: { channelId: "driver_wallet" },
      },
    });
  } catch (error) {
    logger.warn("wallet_push_failed", { error: String(error) });
  }
}

async function handleThresholdSideEffects(
  db,
  {
    driverId,
    beforeOutstanding,
    afterOutstanding,
    beforeBlocked,
    afterBlocked,
    thresholds,
    wallet,
    settlementApproved = false,
  },
) {
  const events = [];
  const prevLevel = computeWalletStatus(beforeOutstanding, thresholds);
  const nextLevel = computeWalletStatus(afterOutstanding, thresholds);

  if (
    beforeOutstanding < thresholds.warningLevel1 &&
    afterOutstanding >= thresholds.warningLevel1
  ) {
    events.push("driver_cash_warning_300");
  }
  if (
    beforeOutstanding < thresholds.warningLevel2 &&
    afterOutstanding >= thresholds.warningLevel2
  ) {
    events.push("driver_cash_warning_450");
  }
  if (!beforeBlocked && afterBlocked) {
    events.push("driver_cash_blocked");
  }
  if (beforeBlocked && !afterBlocked) {
    events.push("driver_cash_unblocked");
  }

  for (const eventName of events) {
    await trackAnalyticsEventInternal(db, {
      type: eventName,
      userId: driverId,
      screen: "driver_wallet",
    });
  }

  let notifyLevel = null;
  let notifyTitle = null;
  let notifyBody = null;

  if (settlementApproved) {
    notifyLevel = "settlement_approved";
    notifyTitle = "تم اعتماد التسوية";
    notifyBody = "تم اعتماد عملية التسوية وإعادة تفعيل الحساب.";
  } else if (afterBlocked && wallet.walletLastNotifiedLevel !== "blocked") {
    notifyLevel = "blocked";
    notifyTitle = "إيقاف استقبال الطلبات";
    notifyBody =
      "تم إيقاف استقبال الطلبات الجديدة لحين تسوية المبالغ المستحقة.";
  } else if (
    afterOutstanding >= thresholds.warningLevel2 &&
    !afterBlocked &&
    wallet.walletLastNotifiedLevel !== "near_block" &&
    wallet.walletLastNotifiedLevel !== "blocked"
  ) {
    notifyLevel = "near_block";
    const remaining = Math.max(0, thresholds.blockLevel - afterOutstanding);
    notifyTitle = "تحذير شديد";
    notifyBody = `وصلت إلى ${Math.round(afterOutstanding)} جنيه مستحقة. متبقي ${remaining} جنيه قبل الحظر.`;
  } else if (
    afterOutstanding >= thresholds.warningLevel1 &&
    afterOutstanding < thresholds.warningLevel2 &&
    wallet.walletLastNotifiedLevel !== "needs_attention" &&
    wallet.walletLastNotifiedLevel !== "near_block" &&
    wallet.walletLastNotifiedLevel !== "blocked"
  ) {
    notifyLevel = "needs_attention";
    notifyTitle = "تحذير تسوية";
    notifyBody = `وصلت إلى ${Math.round(afterOutstanding)} جنيه مستحقة للشركة. يرجى التسوية قريباً.`;
  } else if (
    beforeBlocked &&
    !afterBlocked &&
    wallet.walletLastNotifiedLevel === "blocked"
  ) {
    notifyLevel = "unblocked";
    notifyTitle = "تم فك الحظر";
    notifyBody = "يمكنك الآن استقبال الطلبات بعد تسوية المبلغ المستحق.";
  }

  if (notifyLevel && notifyTitle && notifyBody) {
    await sendWalletPush({
      token: wallet.fcmToken,
      title: notifyTitle,
      body: notifyBody,
      type: `wallet_${notifyLevel}`,
      route: "/wallet",
    });
    const levelToStore =
      notifyLevel === "settlement_approved" || notifyLevel === "unblocked"
        ? nextLevel
        : notifyLevel;
    await db.collection("users").doc(driverId).update({
      walletLastNotifiedLevel: levelToStore,
      updatedAt: FieldValue.serverTimestamp(),
    });
  } else if (nextLevel === "regular" && prevLevel !== "regular") {
    await db.collection("users").doc(driverId).update({
      walletLastNotifiedLevel: "regular",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

/**
 * Credit driver wallet on delivery completion (idempotent per order).
 */
async function applyDeliveryWalletCredits(db, { driverId, orderId, order }) {
  const idempotencyRef = db.collection(TX_COLLECTION).doc(`delivery_${orderId}`);
  const existing = await idempotencyRef.get();
  if (existing.exists) {
    return { skipped: true, reason: "already_processed" };
  }

  const thresholds = await loadWalletThresholds(db);
  const driverRef = db.collection("users").doc(driverId);
  const deliveryFee =
    typeof order.deliveryFee === "number" ? roundMoney(order.deliveryFee) : 0;
  const codAmount = isCodPayment(order.paymentMethod)
    ? orderPayableTotal(order)
    : 0;

  let result = {};

  await db.runTransaction(async (tx) => {
    const idemSnap = await tx.get(idempotencyRef);
    if (idemSnap.exists) {
      result = { skipped: true, reason: "already_processed" };
      return;
    }

    const driverSnap = await tx.get(driverRef);
    if (!driverSnap.exists) {
      throw new Error("DRIVER_NOT_FOUND");
    }

    const before = readWalletFields(driverSnap.data());
    let earnings = before.earningsBalance;
    let outstanding = before.outstandingBalance;

    if (deliveryFee > 0) {
      earnings = roundMoney(earnings + deliveryFee);
    }
    if (codAmount > 0) {
      outstanding = roundMoney(outstanding + codAmount);
    }

    const net = roundMoney(earnings - outstanding);
    const walletStatus = computeWalletStatus(outstanding, thresholds);
    const driverCashBlocked = isDriverCashBlocked(outstanding, thresholds);

    const userUpdate = {
      earningsBalance: earnings,
      outstandingBalance: outstanding,
      netBalance: net,
      walletStatus,
      driverCashBlocked,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (codAmount > 0) {
      userUpdate.lastCodCollectionAt = FieldValue.serverTimestamp();
    }

    tx.update(driverRef, userUpdate);

    const baseTx = {
      driverId,
      earningsBalanceBefore: before.earningsBalance,
      earningsBalanceAfter: earnings,
      outstandingBalanceBefore: before.outstandingBalance,
      outstandingBalanceAfter: outstanding,
      balanceBefore: before.netBalance,
      balanceAfter: net,
      orderId,
      performedBy: "system",
      performedByRole: "system",
      source: "cloud_function",
      referenceId: orderId,
    };

    if (deliveryFee > 0) {
      writeWalletTransaction(tx, db, {
        ...baseTx,
        id: `delivery_earn_${orderId}`,
        type: "delivery_earnings",
        transactionType: "earning",
        amount: deliveryFee,
        notes: "عمولة توصيل",
      });
    }

    if (codAmount > 0) {
      writeWalletTransaction(tx, db, {
        ...baseTx,
        id: `cod_collect_${orderId}`,
        type: "cod_collection",
        transactionType: "cod_collection",
        amount: codAmount,
        notes: "تحصيل نقدي عند الاستلام",
      });
    }

    writeWalletTransaction(tx, db, {
      ...baseTx,
      id: `delivery_${orderId}`,
      type: "delivery_completed",
      transactionType: "earning",
      amount: roundMoney(deliveryFee + codAmount),
      notes: "إكمال توصيل",
    });

    result = {
      skipped: false,
      earningsBalance: earnings,
      outstandingBalance: outstanding,
      netBalance: net,
      walletStatus,
      driverCashBlocked,
      deliveryFee,
      codAmount,
      beforeOutstanding: before.outstandingBalance,
      beforeBlocked: before.driverCashBlocked,
    };
  });

  if (result.skipped) return result;

  if (result.codAmount > 0) {
    await trackAnalyticsEventInternal(db, {
      type: "cod_collected",
      userId: driverId,
      screen: "driver_wallet",
      metadata: { orderId, amount: result.codAmount },
    });
  }

  const driverSnap = await driverRef.get();
  const wallet = readWalletFields(driverSnap.data() || {});

  await handleThresholdSideEffects(db, {
    driverId,
    beforeOutstanding: result.beforeOutstanding,
    afterOutstanding: result.outstandingBalance,
    beforeBlocked: result.beforeBlocked,
    afterBlocked: result.driverCashBlocked,
    thresholds,
    wallet,
  });

  return result;
}

/**
 * Admin settlement — reduces outstanding balance.
 */
async function applyWalletSettlement(
  db,
  {
    driverId,
    amount,
    notes,
    createdBy,
    source = "admin_panel",
    referenceId = null,
    performedByRole = "staff",
  },
) {
  const settlementAmount = roundMoney(amount);
  if (settlementAmount <= 0) {
    throw new Error("INVALID_AMOUNT");
  }

  const thresholds = await loadWalletThresholds(db);
  const driverRef = db.collection("users").doc(driverId);
  const txId = referenceId
    ? `settlement_${referenceId}`
    : `settlement_${driverId}_${Date.now()}`;

  let result = {};

  await db.runTransaction(async (tx) => {
    const driverSnap = await tx.get(driverRef);
    if (!driverSnap.exists) throw new Error("DRIVER_NOT_FOUND");

    const before = readWalletFields(driverSnap.data());
    const outstanding = roundMoney(
      Math.max(0, before.outstandingBalance - settlementAmount),
    );
    const net = roundMoney(before.earningsBalance - outstanding);
    const walletStatus = computeWalletStatus(outstanding, thresholds);
    const driverCashBlocked = isDriverCashBlocked(outstanding, thresholds);

    tx.update(driverRef, {
      outstandingBalance: outstanding,
      netBalance: net,
      walletStatus,
      driverCashBlocked,
      lastSettlementAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    writeWalletTransaction(tx, db, {
      id: txId,
      driverId,
      type: "settlement",
      transactionType: "settlement",
      amount: settlementAmount,
      balanceBefore: before.netBalance,
      balanceAfter: net,
      earningsBalanceBefore: before.earningsBalance,
      earningsBalanceAfter: before.earningsBalance,
      outstandingBalanceBefore: before.outstandingBalance,
      outstandingBalanceAfter: outstanding,
      notes: notes || "تسوية إيداع",
      performedBy: createdBy || "system",
      performedByRole,
      source,
      referenceId,
    });

    result = {
      outstandingBalance: outstanding,
      netBalance: net,
      walletStatus,
      driverCashBlocked,
      beforeOutstanding: before.outstandingBalance,
      beforeBlocked: before.driverCashBlocked,
      wasBlocked: before.driverCashBlocked,
    };
  });

  await trackAnalyticsEventInternal(db, {
    type: "wallet_settlement",
    userId: driverId,
    screen: "admin_wallet",
    metadata: { amount: settlementAmount, createdBy, source, referenceId },
  });

  const driverSnap = await driverRef.get();
  const wallet = readWalletFields(driverSnap.data() || {});

  await handleThresholdSideEffects(db, {
    driverId,
    beforeOutstanding: result.beforeOutstanding,
    afterOutstanding: result.outstandingBalance,
    beforeBlocked: result.beforeBlocked,
    afterBlocked: result.driverCashBlocked,
    thresholds,
    wallet,
    settlementApproved: source === "driver_request" || result.wasBlocked,
  });

  return result;
}

function isCashBlockedUser(user) {
  return user?.driverCashBlocked === true;
}

module.exports = {
  TX_COLLECTION,
  LEGACY_TYPE_MAP,
  mapTransactionType,
  isCodPayment,
  orderPayableTotal,
  readWalletFields,
  writeWalletTransaction,
  applyDeliveryWalletCredits,
  applyWalletSettlement,
  isCashBlockedUser,
  sendWalletPush,
};
