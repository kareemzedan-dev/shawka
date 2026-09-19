const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { checkRateLimit } = require("./rateLimit");
const { FUNCTIONS_REGION } = require("./shared/region");
const {
  promotionDiscount,
  roundMoney,
} = require("./customerOrdersCore");

function asTrimmedString(value, maxLength) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function activePromotion(data, payload, now) {
  if (!data || data.isActive !== true) return false;
  const startsAt = data.startsAt?.toMillis?.();
  const endsAt = data.endsAt?.toMillis?.();
  if (!startsAt || !endsAt || now < startsAt || now > endsAt) return false;
  const governorates = Array.isArray(data.governorates)
    ? data.governorates.map(String)
    : data.governorate
      ? [String(data.governorate)]
      : [];
  if (
    governorates.length > 0 &&
    payload.governorate &&
    !governorates.includes(payload.governorate)
  ) {
    return false;
  }
  return true;
}

function includesAnyWhenConfigured(values, candidates) {
  if (!Array.isArray(values) || values.length === 0) return true;
  const allowed = new Set(values.map(String));
  return candidates.some((candidate) => allowed.has(String(candidate)));
}

/**
 * Cart-only coupon preview. Does not require a delivery address.
 * Final monetary authority remains previewCustomerCheckout + createCustomerOrders.
 */
const validateCartCoupon = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "يجب تسجيل الدخول للتحقق من الكوبون.");
    }

    const data = request.data && typeof request.data === "object" ? request.data : {};
    const couponCode = asTrimmedString(data.couponCode, 64).toUpperCase();
    const governorate = asTrimmedString(data.governorate, 80);
    const storeIds = Array.isArray(data.storeIds)
      ? data.storeIds.map((id) => asTrimmedString(String(id), 128)).filter(Boolean)
      : [];
    const categoryIds = Array.isArray(data.categoryIds)
      ? data.categoryIds.map((id) => asTrimmedString(String(id), 64)).filter(Boolean)
      : [];
    const productIds = Array.isArray(data.productIds)
      ? data.productIds.map((id) => asTrimmedString(String(id), 128)).filter(Boolean)
      : [];
    const subtotal = roundMoney(Math.max(0, Number(data.subtotal || 0)));

    if (!couponCode) {
      throw new HttpsError("invalid-argument", "INVALID_COUPON");
    }

    const db = getFirestore();
    const uid = request.auth.uid;
    await checkRateLimit(db, `cart-coupon:${uid}`, 40, 60 * 1000);

    const snap = await db
      .collection("promotions")
      .where("code", "==", couponCode)
      .limit(1)
      .get();

    if (snap.empty) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: "",
        freeDelivery: false,
        rejectionCode: "INVALID_COUPON",
        message: "كود الخصم غير صالح أو منتهي",
      };
    }

    const doc = snap.docs[0];
    const promotion = doc.data() || {};
    const now = Date.now();
    if (!activePromotion(promotion, { governorate }, now)) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: String(promotion.type || ""),
        freeDelivery: false,
        rejectionCode: "INVALID_COUPON",
        message: "كود الخصم غير صالح أو منتهي",
      };
    }

    const scopedStoreIds = Array.isArray(promotion.storeIds)
      ? promotion.storeIds.map(String)
      : promotion.storeId
        ? [String(promotion.storeId)]
        : [];
    if (
      scopedStoreIds.length > 0 &&
      !includesAnyWhenConfigured(scopedStoreIds, storeIds)
    ) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: String(promotion.type || ""),
        freeDelivery: false,
        rejectionCode: "COUPON_STORE_MISMATCH",
        message: "هذا الكوبون غير متاح لمتاجر سلتك الحالية",
      };
    }

    const scopedCategories = Array.isArray(promotion.categoryIds)
      ? promotion.categoryIds.map(String)
      : [];
    if (
      scopedCategories.length > 0 &&
      !includesAnyWhenConfigured(scopedCategories, categoryIds)
    ) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: String(promotion.type || ""),
        freeDelivery: false,
        rejectionCode: "COUPON_CATEGORY_MISMATCH",
        message: "هذا الكوبون غير متاح لفئات المنتجات في سلتك",
      };
    }

    const scopedProducts = Array.isArray(promotion.productIds)
      ? promotion.productIds.map(String)
      : [];
    if (
      scopedProducts.length > 0 &&
      !includesAnyWhenConfigured(scopedProducts, productIds)
    ) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: String(promotion.type || ""),
        freeDelivery: false,
        rejectionCode: "COUPON_PRODUCT_MISMATCH",
        message: "هذا الكوبون غير متاح لمنتجات سلتك",
      };
    }

    if (Number(promotion.minOrderAmount || 0) > subtotal) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: String(promotion.type || ""),
        freeDelivery: false,
        rejectionCode: "PROMOTION_MINIMUM_NOT_MET",
        message: "قيمة الطلب أقل من الحد الأدنى لهذا العرض",
      };
    }

    if (
      Number(promotion.usageLimit || 0) > 0 &&
      Number(promotion.usageCount || 0) >= Number(promotion.usageLimit)
    ) {
      return {
        valid: false,
        code: couponCode,
        discountAmount: 0,
        type: String(promotion.type || ""),
        freeDelivery: false,
        rejectionCode: "PROMOTION_USAGE_EXHAUSTED",
        message: "انتهى الحد الأقصى لاستخدام هذا العرض",
      };
    }

    if (Number(promotion.perUserLimit || 0) > 0) {
      const usageSnap = await doc.ref.collection("users").doc(uid).get();
      if (
        Number(usageSnap.data()?.usageCount || 0) >=
        Number(promotion.perUserLimit)
      ) {
        return {
          valid: false,
          code: couponCode,
          discountAmount: 0,
          type: String(promotion.type || ""),
          freeDelivery: false,
          rejectionCode: "PROMOTION_USER_LIMIT_EXHAUSTED",
          message: "لقد استخدمت هذا العرض بالحد الأقصى المسموح",
        };
      }
    }

    const freeDelivery = promotion.type === "freeDelivery";
    const discountAmount = freeDelivery
      ? 0
      : promotionDiscount(promotion, subtotal);

    return {
      valid: true,
      code: couponCode,
      discountAmount,
      type: String(promotion.type || ""),
      freeDelivery,
      expiresAt: promotion.endsAt?.toMillis?.() || 0,
      rejectionCode: "",
      message: "",
    };
  },
);

module.exports = { validateCartCoupon };
