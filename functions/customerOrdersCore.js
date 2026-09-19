const MAX_ORDERS_PER_CHECKOUT = 10;
const MAX_LINES_PER_ORDER = 50;
const MAX_QUANTITY_PER_LINE = 99;

function asTrimmedString(value, maxLength) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function asFiniteNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

/** Rejects missing / Null-Island coordinates so checkout can fall back to zone defaults. */
function asGeoCoordinate(value) {
  const number = asFiniteNumber(value);
  if (number === null) return null;
  if (Math.abs(number) < 0.0001) return null;
  return number;
}

function normalizeCheckoutPayload(raw) {
  const data = raw && typeof raw === "object" ? raw : {};
  const orders = Array.isArray(data.orders) ? data.orders : [];

  if (orders.length === 0 || orders.length > MAX_ORDERS_PER_CHECKOUT) {
    throw new Error("INVALID_ORDER_COUNT");
  }

  const addressLat = asFiniteNumber(data.addressLat);
  const addressLng = asFiniteNumber(data.addressLng);
  if (
    addressLat === null ||
    addressLng === null ||
    addressLat < -90 ||
    addressLat > 90 ||
    addressLng < -180 ||
    addressLng > 180
  ) {
    throw new Error("INVALID_DELIVERY_COORDINATES");
  }

  const paymentMethod = asTrimmedString(data.paymentMethod, 32) || "cash";
  if (!/^[a-zA-Z0-9_-]+$/.test(paymentMethod)) {
    throw new Error("INVALID_PAYMENT_METHOD");
  }

  const normalizedOrders = orders.map(normalizeOrder);
  const uniqueStores = new Set(normalizedOrders.map((order) => order.storeId));
  if (uniqueStores.size !== normalizedOrders.length) {
    throw new Error("DUPLICATE_STORE_ORDER");
  }

  return {
    checkoutRequestId:
      asTrimmedString(data.checkoutRequestId, 80)
        .replace(/[^a-zA-Z0-9_-]/g, ""),
    customerName: asTrimmedString(data.customerName, 120),
    phone: asTrimmedString(data.phone, 32),
    governorate: asTrimmedString(data.governorate, 80),
    address: asTrimmedString(data.address, 500),
    addressFormatted: asTrimmedString(data.addressFormatted, 500),
    addressPlaceId: asTrimmedString(data.addressPlaceId, 200),
    addressLat,
    addressLng,
    paymentMethod,
    couponCode: asTrimmedString(data.couponCode, 64).toUpperCase(),
    orderNote: asTrimmedString(data.orderNote, 500),
    orders: normalizedOrders,
  };
}

function normalizeOrder(raw) {
  const data = raw && typeof raw === "object" ? raw : {};
  const storeId = asTrimmedString(data.storeId, 128);
  const category = asTrimmedString(data.category, 128);
  const lines = Array.isArray(data.lineItems) ? data.lineItems : [];

  if (!storeId) throw new Error("STORE_ID_REQUIRED");
  if (!category) {
    throw new Error("INVALID_STORE_CATEGORY");
  }
  if (lines.length === 0 || lines.length > MAX_LINES_PER_ORDER) {
    throw new Error("INVALID_LINE_COUNT");
  }

  return {
    storeId,
    category,
    lineItems: lines.map((line) => {
      const productId = asTrimmedString(line?.productId, 128);
      const quantity = Number(line?.quantity);
      const addonIds = Array.isArray(line?.addonIds)
        ? [...new Set(line.addonIds.map((id) => asTrimmedString(id, 128)))]
            .filter(Boolean)
            .slice(0, 20)
        : [];

      if (!productId) throw new Error("PRODUCT_ID_REQUIRED");
      if (
        !Number.isInteger(quantity) ||
        quantity < 1 ||
        quantity > MAX_QUANTITY_PER_LINE
      ) {
        throw new Error("INVALID_QUANTITY");
      }

      return {
        productId,
        quantity,
        addonIds,
        note: asTrimmedString(line?.note, 300),
      };
    }),
  };
}

function resolveProductLine(product, requested) {
  if (product.isAvailable === false) throw new Error("PRODUCT_UNAVAILABLE");
  if (product.trackStock === true) {
    const stock = Number(product.stockQuantity || 0);
    if (!Number.isInteger(stock) || stock < requested.quantity) {
      throw new Error("INSUFFICIENT_STOCK");
    }
  }

  const maxPerCustomer = Number(product.maxPerCustomer || 0);
  if (
    Number.isInteger(maxPerCustomer) &&
    maxPerCustomer > 0 &&
    requested.quantity > maxPerCustomer
  ) {
    throw new Error("CUSTOMER_QUANTITY_LIMIT");
  }

  const basePrice = asFiniteNumber(product.price);
  if (basePrice === null || basePrice < 0) throw new Error("INVALID_PRODUCT_PRICE");

  const availableAddons = new Map(
    (Array.isArray(product.addons) ? product.addons : [])
      .filter((addon) => addon && addon.isAvailable !== false)
      .map((addon) => [String(addon.id || ""), addon]),
  );

  const selectedAddons = requested.addonIds.map((id) => {
    const addon = availableAddons.get(id);
    if (!addon) throw new Error("INVALID_ADDON");
    const price = asFiniteNumber(addon.price);
    if (price === null || price < 0) throw new Error("INVALID_ADDON_PRICE");
    return {
      id,
      name: asTrimmedString(addon.name, 120),
      price,
    };
  });

  const unitPrice = selectedAddons.reduce(
    (sum, addon) => sum + addon.price,
    basePrice,
  );
  const productName = asTrimmedString(product.name, 160);
  const addonLabel = selectedAddons.map((addon) => addon.name).filter(Boolean);

  return {
    productId: requested.productId,
    productName:
      addonLabel.length > 0
        ? `${productName} (${addonLabel.join("، ")})`
        : productName,
    imageUrl: asTrimmedString(product.imageUrl, 2000),
    imageThumbUrl: asTrimmedString(product.imageThumbUrl, 2000),
    quantity: requested.quantity,
    unitPrice: Number(unitPrice.toFixed(2)),
    addonIds: selectedAddons.map((addon) => addon.id),
    addons: selectedAddons,
    note: requested.note,
  };
}

/**
 * يمنع تجاوز حد العميل عبر تقسيم نفس المنتج على عدة أسطر (إضافات/ملاحظات).
 * @param {Array<{productId: string, quantity: number}>} lines
 * @param {Map<string, object>|Record<string, object>} productsById
 */
function assertCustomerQuantityLimits(lines, productsById) {
  const totals = new Map();
  for (const line of lines) {
    const productId = String(line.productId || "");
    if (!productId) continue;
    totals.set(productId, (totals.get(productId) || 0) + Number(line.quantity || 0));
  }
  for (const [productId, totalQty] of totals.entries()) {
    const product =
      productsById instanceof Map
        ? productsById.get(productId)
        : productsById[productId];
    if (!product) continue;
    const maxPerCustomer = Number(product.maxPerCustomer || 0);
    if (
      Number.isInteger(maxPerCustomer) &&
      maxPerCustomer > 0 &&
      totalQty > maxPerCustomer
    ) {
      throw new Error("CUSTOMER_QUANTITY_LIMIT");
    }
  }
}

function promotionDiscount(promotion, eligibleSubtotal) {
  if (!promotion || eligibleSubtotal <= 0) return 0;
  const value = Math.max(0, Number(promotion.value || 0));
  const maxDiscount = Math.max(0, Number(promotion.maxDiscount || 0));
  let discount = 0;
  if (promotion.type === "percent") {
    discount = Math.min(eligibleSubtotal * value / 100, eligibleSubtotal * 0.5);
  } else if (promotion.type === "fixedAmount") {
    discount = Math.min(value, eligibleSubtotal);
  }
  if (maxDiscount > 0) {
    discount = Math.min(discount, maxDiscount);
  }
  return roundMoney(discount);
}

function roundMoney(value) {
  const number = Number(value);
  return Number.isFinite(number) ? Number(number.toFixed(2)) : 0;
}

function allocateMoney(total, weights) {
  const amount = roundMoney(total);
  const normalized = weights.map((weight) =>
    Math.max(0, Number.isFinite(Number(weight)) ? Number(weight) : 0),
  );
  const weightTotal = normalized.reduce((sum, weight) => sum + weight, 0);
  if (normalized.length === 0) return [];
  if (amount === 0 || weightTotal <= 0) return normalized.map(() => 0);
  const lastPositiveIndex = normalized.findLastIndex((weight) => weight > 0);
  let allocated = 0;
  return normalized.map((weight, index) => {
    if (weight <= 0) return 0;
    if (index === lastPositiveIndex) {
      return roundMoney(amount - allocated);
    }
    const share = roundMoney(amount * weight / weightTotal);
    allocated = roundMoney(allocated + share);
    return share;
  });
}

function haversineKm(fromLat, fromLng, toLat, toLng) {
  const values = [fromLat, fromLng, toLat, toLng].map(Number);
  if (values.some((value) => !Number.isFinite(value))) return 0;
  const [lat1, lng1, lat2, lng2] = values;
  const toRadians = (degrees) => degrees * Math.PI / 180;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const DEFAULT_DELIVERY_TIERS = [
  { minKm: 0, maxKm: 3, fee: 15 },
  { minKm: 3, maxKm: 7, fee: 25 },
  { minKm: 7, maxKm: 10, fee: 35 },
  { minKm: 10, maxKm: 15, fee: 50 },
];

const DEFAULT_ZONE = { lat: 30.0444, lng: 31.2357 };

function resolveDeliveryTier(distanceKm, tiers, maxRoadKm) {
  if (!Number.isFinite(distanceKm) || distanceKm < 0) {
    return { isDeliverable: false, fee: 0 };
  }
  // Same-building / pin-overlap still counts as deliverable.
  const effectiveDistance = distanceKm === 0 ? 0.01 : distanceKm;
  const maxDistance = Math.max(0, Number(maxRoadKm || 0));
  if (maxDistance > 0 && effectiveDistance > maxDistance) {
    return { isDeliverable: false, fee: 0 };
  }
  const sourceTiers =
    Array.isArray(tiers) && tiers.length > 0 ? tiers : DEFAULT_DELIVERY_TIERS;
  const normalized = sourceTiers
    .map((tier) => ({
      minKm: Number(tier?.minKm || 0),
      maxKm: Number(tier?.maxKm || 0),
      fee: Math.max(0, Number(tier?.fee || 0)),
    }))
    .filter(
      (tier) =>
        Number.isFinite(tier.minKm) &&
        Number.isFinite(tier.maxKm) &&
        Number.isFinite(tier.fee) &&
        tier.maxKm > tier.minKm,
    )
    .sort((a, b) => a.minKm - b.minKm);
  for (let index = 0; index < normalized.length; index += 1) {
    const tier = normalized[index];
    const inRange =
      index === 0
        ? effectiveDistance >= tier.minKm && effectiveDistance <= tier.maxKm
        : effectiveDistance > tier.minKm && effectiveDistance <= tier.maxKm;
    if (inRange) return { isDeliverable: true, fee: roundMoney(tier.fee) };
  }
  return { isDeliverable: false, fee: 0 };
}

function deliveryQuoteForStore(store, settings, payload) {
  const originLat =
    asGeoCoordinate(store.latitude) ??
    asGeoCoordinate(settings.deliveryZoneLat) ??
    DEFAULT_ZONE.lat;
  const originLng =
    asGeoCoordinate(store.longitude) ??
    asGeoCoordinate(settings.deliveryZoneLng) ??
    DEFAULT_ZONE.lng;

  // Deterministic road-distance estimate. It is calculated only on the server
  // so the displayed quote and the persisted order always share one contract.
  const straightKm = haversineKm(
    originLat,
    originLng,
    payload.addressLat,
    payload.addressLng,
  );
  const roadFactor = Math.min(
    2,
    Math.max(1, Number(settings.deliveryRoadFactor || 1.35)),
  );
  const distanceKm = roundMoney(straightKm * roadFactor);
  const tiers =
    store.useGlobalDeliveryPricing === false &&
    Array.isArray(store.deliveryPricingTiers) &&
    store.deliveryPricingTiers.length > 0
      ? store.deliveryPricingTiers
      : Array.isArray(settings.deliveryPricingTiers) &&
          settings.deliveryPricingTiers.length > 0
        ? settings.deliveryPricingTiers
        : DEFAULT_DELIVERY_TIERS;
  const tier = resolveDeliveryTier(
    distanceKm,
    tiers,
    Number(settings.deliveryMaxRoadKm) > 0
      ? Number(settings.deliveryMaxRoadKm)
      : 15,
  );
  if (!tier.isDeliverable) {
    throw new Error("STORE_OUT_OF_DELIVERY_ZONE");
  }

  const etaMinutes = Math.min(
    120,
    Math.max(
      5,
      Math.round(
        distanceKm * Math.max(1, Number(settings.deliveryMinutesPerKm || 2.2)),
      ),
    ),
  );
  return {
    distanceKm,
    etaMinutes,
    rawFee: tier.fee,
  };
}

function calculateCheckoutPricing({
  resolvedOrders,
  settings,
  payload,
  promotion,
}) {
  const subtotal = roundMoney(
    resolvedOrders.reduce((sum, order) => sum + order.subtotal, 0),
  );
  const eligibleOrders = resolvedOrders.filter((order) => {
    if (!promotion) return false;
    const storeIds = Array.isArray(promotion.storeIds)
      ? promotion.storeIds.map(String)
      : promotion.storeId
        ? [String(promotion.storeId)]
        : [];
    if (storeIds.length > 0 && !storeIds.includes(order.storeId)) return false;
    const categoryIds = Array.isArray(promotion.categoryIds)
      ? promotion.categoryIds.map(String)
      : [];
    if (
      categoryIds.length > 0 &&
      !categoryIds.includes(String(order.store.categoryId || "")) &&
      !categoryIds.includes(String(order.category || ""))
    ) {
      return false;
    }
    const productIds = Array.isArray(promotion.productIds)
      ? new Set(promotion.productIds.map(String))
      : null;
    return (
      !productIds ||
      order.lines.some((line) => productIds.has(String(line.productId)))
    );
  });
  const eligibleSubtotal = roundMoney(
    eligibleOrders.reduce((sum, order) => sum + order.subtotal, 0),
  );
  if (
    promotion &&
    Number(promotion.minOrderAmount || 0) > eligibleSubtotal
  ) {
    throw new Error("PROMOTION_MINIMUM_NOT_MET");
  }
  const discountAmount = promotionDiscount(promotion, eligibleSubtotal);

  const freeDeliveryThreshold = Math.max(
    0,
    Number(settings.freeDeliveryThreshold || 0),
  );
  const globalFreeDelivery =
    freeDeliveryThreshold > 0 && subtotal >= freeDeliveryThreshold;
  const promotionFreeDelivery = promotion?.type === "freeDelivery";

  const quotes = resolvedOrders.map((order) => {
    const quote = deliveryQuoteForStore(order.store, settings, payload);
    const storeThreshold = Math.max(
      0,
      Number(order.store.freeDeliveryThreshold || 0),
    );
    const storeFreeDelivery =
      storeThreshold > 0 && order.subtotal >= storeThreshold;
    const promotionApplies =
      promotionFreeDelivery && eligibleOrders.includes(order);
    return {
      ...quote,
      storeId: order.storeId,
      fee:
        globalFreeDelivery || storeFreeDelivery || promotionApplies
          ? 0
          : quote.rawFee,
    };
  });
  const deliveryFee = roundMoney(
    quotes.reduce((sum, quote) => sum + quote.fee, 0),
  );
  const serviceFeeBase = Math.max(
    0,
    Number(settings.checkoutServiceFeeFixed || 0),
  );
  const serviceFeePercent = Math.min(
    100,
    Math.max(0, Number(settings.checkoutServiceFeePercent || 0)),
  );
  const serviceFee = roundMoney(
    serviceFeeBase + subtotal * serviceFeePercent / 100,
  );
  const paymentConfig = (
    Array.isArray(settings.checkoutPaymentMethods)
      ? settings.checkoutPaymentMethods
      : []
  ).find((method) => String(method?.id || "") === payload.paymentMethod);
  const paymentFee = roundMoney(
    Math.max(0, Number(paymentConfig?.feeFixed || 0)) +
      subtotal *
        Math.min(
          100,
          Math.max(0, Number(paymentConfig?.feePercent || 0)),
        ) /
        100,
  );
  const taxableAmount = Math.max(
    0,
    subtotal - discountAmount + serviceFee + paymentFee,
  );
  const taxPercent = Math.min(
    100,
    Math.max(0, Number(settings.checkoutTaxPercent || 0)),
  );
  const taxes = roundMoney(taxableAmount * taxPercent / 100);
  const grandTotal = roundMoney(
    subtotal +
      deliveryFee +
      serviceFee +
      paymentFee +
      taxes -
      discountAmount,
  );

  const subtotalWeights = resolvedOrders.map((order) => order.subtotal);
  const eligibleWeights = resolvedOrders.map((order) =>
    eligibleOrders.includes(order) ? order.subtotal : 0,
  );
  const discountAllocations = allocateMoney(discountAmount, eligibleWeights);
  const serviceFeeAllocations = allocateMoney(serviceFee, subtotalWeights);
  const paymentFeeAllocations = allocateMoney(paymentFee, subtotalWeights);
  const taxAllocations = allocateMoney(taxes, subtotalWeights);

  const orders = resolvedOrders.map((order, index) => {
    const quote = quotes.find((entry) => entry.storeId === order.storeId);
    const orderDiscount = discountAllocations[index];
    const orderServiceFee = serviceFeeAllocations[index];
    const orderPaymentFee = paymentFeeAllocations[index];
    const orderTaxes = taxAllocations[index];
    const orderGrandTotal = roundMoney(
      order.subtotal +
        (quote?.fee || 0) +
        orderServiceFee +
        orderPaymentFee +
        orderTaxes -
        orderDiscount,
    );
    return {
      storeId: order.storeId,
      subtotal: order.subtotal,
      deliveryFee: quote?.fee || 0,
      rawDeliveryFee: quote?.rawFee || 0,
      distanceKm: quote?.distanceKm || 0,
      etaMinutes: quote?.etaMinutes || 0,
      discountAmount: orderDiscount,
      serviceFee: orderServiceFee,
      paymentFee: orderPaymentFee,
      taxes: orderTaxes,
      grandTotal: orderGrandTotal,
    };
  });

  return {
    currency: "EGP",
    subtotal,
    deliveryFee,
    discountAmount,
    serviceFee,
    paymentFee,
    taxes,
    grandTotal,
    couponCode: promotion ? payload.couponCode : "",
    couponExpiresAt: promotion
      ? Number(
          promotion.endsAt?.toMillis?.() ||
            promotion.endsAt?.getTime?.() ||
            Date.parse(promotion.endsAt || "") ||
            0,
        )
      : 0,
    distanceKm: quotes.reduce(
      (max, quote) => Math.max(max, quote.distanceKm),
      0,
    ),
    etaMinutes: quotes.reduce(
      (max, quote) => Math.max(max, quote.etaMinutes),
      0,
    ),
    orders,
  };
}

module.exports = {
  MAX_ORDERS_PER_CHECKOUT,
  MAX_LINES_PER_ORDER,
  normalizeCheckoutPayload,
  resolveProductLine,
  assertCustomerQuantityLimits,
  promotionDiscount,
  roundMoney,
  allocateMoney,
  haversineKm,
  resolveDeliveryTier,
  deliveryQuoteForStore,
  calculateCheckoutPricing,
};
