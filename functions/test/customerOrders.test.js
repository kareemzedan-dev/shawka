const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeCheckoutPayload,
  resolveProductLine,
  promotionDiscount,
  haversineKm,
  resolveDeliveryTier,
  calculateCheckoutPricing,
  allocateMoney,
} = require("../customerOrdersCore");

function validPayload() {
  return {
    customerName: "Customer",
    governorate: "القاهرة",
    address: "Test address",
    addressLat: 30.04,
    addressLng: 31.23,
    paymentMethod: "cash",
    orders: [
      {
        storeId: "store-1",
        category: "restaurant",
        lineItems: [
          {
            productId: "product-1",
            quantity: 2,
            addonIds: ["cheese"],
          },
        ],
      },
    ],
  };
}

test("normalizes checkout without accepting client prices or customerId", () => {
  const payload = validPayload();
  payload.customerId = "spoofed-user";
  payload.checkoutRequestId = "checkout/request ! 123";
  payload.orders[0].lineItems[0].unitPrice = 0.01;

  const normalized = normalizeCheckoutPayload(payload);
  assert.equal(normalized.orders[0].lineItems[0].productId, "product-1");
  assert.equal("customerId" in normalized, false);
  assert.equal(normalized.checkoutRequestId, "checkoutrequest123");
  assert.equal("unitPrice" in normalized.orders[0].lineItems[0], false);
});

test("rejects invalid coordinates, quantities, and payment methods", () => {
  const invalidCoords = validPayload();
  invalidCoords.addressLat = 120;
  assert.throws(
    () => normalizeCheckoutPayload(invalidCoords),
    /INVALID_DELIVERY_COORDINATES/,
  );

  const invalidQuantity = validPayload();
  invalidQuantity.orders[0].lineItems[0].quantity = 0;
  assert.throws(
    () => normalizeCheckoutPayload(invalidQuantity),
    /INVALID_QUANTITY/,
  );

  const invalidPayment = validPayload();
  invalidPayment.paymentMethod = "forged method!";
  assert.throws(
    () => normalizeCheckoutPayload(invalidPayment),
    /INVALID_PAYMENT_METHOD/,
  );
});

test("resolves product and addon prices from authoritative product data", () => {
  const line = resolveProductLine(
    {
      name: "برجر",
      price: 100,
      isAvailable: true,
      trackStock: true,
      stockQuantity: 5,
      addons: [
        { id: "cheese", name: "جبنة", price: 15, isAvailable: true },
      ],
    },
    {
      productId: "product-1",
      quantity: 2,
      addonIds: ["cheese"],
      note: "",
    },
  );

  assert.equal(line.unitPrice, 115);
  assert.deepEqual(line.addonIds, ["cheese"]);
  assert.match(line.productName, /جبنة/);
});

test("rejects unavailable products, invalid addons, and insufficient stock", () => {
  const requested = {
    productId: "product-1",
    quantity: 2,
    addonIds: [],
    note: "",
  };
  assert.throws(
    () => resolveProductLine({ price: 10, isAvailable: false }, requested),
    /PRODUCT_UNAVAILABLE/,
  );
  assert.throws(
    () =>
      resolveProductLine(
        {
          price: 10,
          isAvailable: true,
          trackStock: true,
          stockQuantity: 1,
        },
        requested,
      ),
    /INSUFFICIENT_STOCK/,
  );
  assert.throws(
    () =>
      resolveProductLine(
        {
          price: 10,
          isAvailable: true,
          maxPerCustomer: 1,
        },
        requested,
      ),
    /CUSTOMER_QUANTITY_LIMIT/,
  );
  assert.throws(
    () =>
      resolveProductLine(
        { price: 10, isAvailable: true, addons: [] },
        { ...requested, addonIds: ["missing"] },
      ),
    /INVALID_ADDON/,
  );
});

test("rejects customer limit across multiple lines of the same product", () => {
  const { assertCustomerQuantityLimits } = require("../customerOrdersCore");
  assert.throws(
    () =>
      assertCustomerQuantityLimits(
        [
          { productId: "p1", quantity: 2 },
          { productId: "p1", quantity: 2 },
        ],
        { p1: { maxPerCustomer: 3 } },
      ),
    /CUSTOMER_QUANTITY_LIMIT/,
  );
  assert.doesNotThrow(() =>
    assertCustomerQuantityLimits(
      [
        { productId: "p1", quantity: 1 },
        { productId: "p1", quantity: 2 },
      ],
      { p1: { maxPerCustomer: 3 } },
    ),
  );
});

test("caps percent discounts and fixed discounts safely", () => {
  assert.equal(
    promotionDiscount({ type: "percent", value: 90 }, 200),
    100,
  );
  assert.equal(
    promotionDiscount({ type: "fixedAmount", value: 500 }, 200),
    200,
  );
  assert.equal(
    promotionDiscount(
      { type: "percent", value: 25, maxDiscount: 20 },
      200,
    ),
    20,
  );
});

test("resolves delivery tiers and rejects out of zone distances", () => {
  const tiers = [
    { minKm: 0, maxKm: 3, fee: 15 },
    { minKm: 3, maxKm: 7, fee: 25 },
  ];
  assert.deepEqual(resolveDeliveryTier(3, tiers, 15), {
    isDeliverable: true,
    fee: 15,
  });
  assert.deepEqual(resolveDeliveryTier(5, tiers, 15), {
    isDeliverable: true,
    fee: 25,
  });
  assert.equal(resolveDeliveryTier(18, tiers, 15).isDeliverable, false);
});

test("calculates every monetary checkout field from one server contract", () => {
  const settings = {
    deliveryZoneLat: 30.0444,
    deliveryZoneLng: 31.2357,
    deliveryRoadFactor: 1.35,
    deliveryMinutesPerKm: 2.2,
    deliveryMaxRoadKm: 15,
    deliveryPricingTiers: [
      { minKm: 0, maxKm: 3, fee: 15 },
      { minKm: 3, maxKm: 7, fee: 25 },
      { minKm: 7, maxKm: 15, fee: 40 },
    ],
    checkoutServiceFeeFixed: 2,
    checkoutServiceFeePercent: 5,
    checkoutTaxPercent: 14,
    checkoutPaymentMethods: [
      { id: "cash", isActive: true, feeFixed: 3, feePercent: 1 },
    ],
  };
  const payload = {
    addressLat: 30.05,
    addressLng: 31.24,
    couponCode: "SAVE10",
    paymentMethod: "cash",
  };
  const resolvedOrders = [
    {
      storeId: "store-1",
      category: "restaurant",
      store: {
        categoryId: "restaurant",
        latitude: 30.0444,
        longitude: 31.2357,
        useGlobalDeliveryPricing: true,
      },
      subtotal: 200,
      lines: [{ productId: "product-1", quantity: 2, unitPrice: 100 }],
    },
  ];
  const pricing = calculateCheckoutPricing({
    resolvedOrders,
    settings,
    payload,
    promotion: {
      type: "percent",
      value: 10,
      storeIds: ["store-1"],
    },
  });

  assert.equal(pricing.subtotal, 200);
  assert.equal(pricing.discountAmount, 20);
  assert.equal(pricing.deliveryFee, 15);
  assert.equal(pricing.serviceFee, 12);
  assert.equal(pricing.paymentFee, 5);
  assert.equal(pricing.taxes, 27.58);
  assert.equal(pricing.grandTotal, 239.58);
  assert.equal(pricing.orders[0].grandTotal, 239.58);
  assert.ok(pricing.distanceKm > 0);
  assert.ok(pricing.etaMinutes >= 5);
});

test("uses deterministic haversine distance for server delivery pricing", () => {
  assert.equal(haversineKm(30, 31, 30, 31), 0);
  assert.ok(haversineKm(30.0444, 31.2357, 30.05, 31.24) > 0);
});

test("falls back when store coordinates are Null Island", () => {
  const settings = {
    deliveryZoneLat: 30.0444,
    deliveryZoneLng: 31.2357,
    deliveryRoadFactor: 1.35,
    deliveryMinutesPerKm: 2.2,
    deliveryMaxRoadKm: 15,
    deliveryPricingTiers: [
      { minKm: 0, maxKm: 3, fee: 15 },
      { minKm: 3, maxKm: 7, fee: 25 },
    ],
  };
  const pricing = calculateCheckoutPricing({
    resolvedOrders: [
      {
        storeId: "store-1",
        category: "restaurant",
        store: {
          latitude: 0,
          longitude: 0,
          useGlobalDeliveryPricing: true,
        },
        subtotal: 100,
        lines: [{ productId: "product-1", quantity: 1, unitPrice: 100 }],
      },
    ],
    settings,
    payload: {
      addressLat: 30.05,
      addressLng: 31.24,
      paymentMethod: "cash",
    },
    promotion: null,
  });
  assert.equal(pricing.deliveryFee, 15);
  assert.ok(pricing.distanceKm > 0);
  assert.ok(pricing.distanceKm < 5);
});

test("allocates rounded money without losing cents", () => {
  const shares = allocateMoney(10, [1, 1, 1]);
  assert.deepEqual(shares, [3.33, 3.33, 3.34]);
  assert.equal(shares.reduce((sum, value) => sum + value, 0), 10);
  assert.deepEqual(allocateMoney(5, [2, 0, 3, 0]), [2, 0, 3, 0]);
});
