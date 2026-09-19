const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");
const { checkRateLimit } = require("./rateLimit");
const { FUNCTIONS_REGION } = require("./shared/region");
const {
  normalizeCheckoutPayload,
  resolveProductLine,
  assertCustomerQuantityLimits,
  calculateCheckoutPricing,
} = require("./customerOrdersCore");
const { isStoreSellable } = require("./shared/storeHours");

function invalidArgument(error) {
  const code = error instanceof Error ? error.message : "INVALID_CHECKOUT";
  return new HttpsError("invalid-argument", code);
}

function isAnonymousAuth(request) {
  const provider =
    request?.auth?.token?.firebase?.sign_in_provider ||
    request?.auth?.token?.sign_in_provider ||
    "";
  return provider === "anonymous";
}

/** عميل فقط — يجب أن يكون معتمداً ونشطاً (أو حساب قديم مكتمل بلا حالة). */
function assertCustomerMayOrder(user) {
  const role = user.role || user.rule || "customer";
  if (role !== "customer") return;

  if (user.isActive === false) {
    throw new HttpsError("permission-denied", "USER_DISABLED");
  }

  const status = String(user.customerApprovalStatus || "").trim();
  const signupComplete = user.signupComplete !== false;
  const proof = String(user.proofImageUrl || "").trim();
  const incomplete =
    status === "incomplete" ||
    signupComplete === false ||
    (user.hasPassword === true && !status && !proof);

  if (incomplete) {
    throw new HttpsError("permission-denied", "ACCOUNT_NOT_APPROVED");
  }
  if (status === "pending") {
    throw new HttpsError("permission-denied", "ACCOUNT_PENDING_APPROVAL");
  }
  if (status === "rejected") {
    throw new HttpsError("permission-denied", "ACCOUNT_NOT_APPROVED");
  }
  if (status === "approved") {
    if (user.isActive !== true) {
      throw new HttpsError("permission-denied", "USER_DISABLED");
    }
    return;
  }
  // فارغ = حساب قديم قبل نظام الموافقة.
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
    !governorates.includes(payload.governorate)
  ) return false;
  return true;
}

function paymentSupported(store, method) {
  const known = {
    cash: store.supportsCash !== false,
    card: store.supportsCard === true,
    wallet:
      store.supportsVodafoneCash === true ||
      store.supportsInstapay === true ||
      store.supportsOnlinePayment === true,
    instapay: store.supportsInstapay === true,
    vodafoneCash: store.supportsVodafoneCash === true,
    online: store.supportsOnlinePayment === true,
  };
  return Object.hasOwn(known, method) ? known[method] === true : true;
}

function sameGovernorate(left, right) {
  const a = String(left || "").trim();
  const b = String(right || "").trim();
  if (!a || !b) return true;
  if (a === b) return true;
  return a.includes(b) || b.includes(a);
}

function paymentConfiguration(settings, method) {
  const configured = Array.isArray(settings.checkoutPaymentMethods)
    ? settings.checkoutPaymentMethods
    : [];
  if (configured.length === 0) {
    // Production settings may not have CMS payment methods yet.
    return { id: method, isActive: true };
  }
  return configured.find(
    (entry) => String(entry?.id || "") === method && entry.isActive === true,
  );
}

function paymentAvailableForOrder({
  settings,
  method,
  store,
  storeId,
  category,
  governorate,
  subtotal,
}) {
  const config = paymentConfiguration(settings, method);
  if (!config || !paymentSupported(store, method)) return false;
  const includesWhenConfigured = (values, value) =>
    !Array.isArray(values) ||
    values.length === 0 ||
    values.map(String).includes(String(value));
  if (!includesWhenConfigured(config.governorates, governorate)) return false;
  if (!includesWhenConfigured(config.storeIds, storeId)) return false;
  if (
    !includesWhenConfigured(
      config.categoryIds,
      store.categoryId || category,
    )
  ) return false;
  if (Number(config.minOrderAmount || 0) > subtotal) return false;
  if (
    Number(config.maxOrderAmount || 0) > 0 &&
    subtotal > Number(config.maxOrderAmount)
  ) return false;
  return true;
}

function publicPricing(pricing) {
  return {
    currency: pricing.currency,
    subtotal: pricing.subtotal,
    deliveryFee: pricing.deliveryFee,
    discountAmount: pricing.discountAmount,
    serviceFee: pricing.serviceFee,
    paymentFee: pricing.paymentFee,
    taxes: pricing.taxes,
    grandTotal: pricing.grandTotal,
    couponCode: pricing.couponCode,
    couponExpiresAt: pricing.couponExpiresAt,
    distanceKm: pricing.distanceKm,
    etaMinutes: pricing.etaMinutes,
    orders: pricing.orders,
  };
}

/**
 * إنشاء الطلبات عملية خادمية ذرية:
 * - هوية العميل تأتي من Auth فقط.
 * - الأسعار/المخزون/المتجر/العرض تُقرأ من Firestore.
 * - خصم المخزون وإنشاء كل طلبات الـ checkout في transaction واحدة.
 */
const createCustomerOrders = onCall(
  {
    region: FUNCTIONS_REGION,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "يجب تسجيل الدخول لإتمام الطلب.");
    }

    let payload;
    try {
      payload = normalizeCheckoutPayload(request.data);
    } catch (error) {
      throw invalidArgument(error);
    }

    const db = getFirestore();
    const uid = request.auth.uid;
    await checkRateLimit(db, `checkout:${uid}`, 8, 60 * 1000);

    const userRef = db.collection("users").doc(uid);
    const settingsRef = db.collection("app_settings").doc("config");
    const requestRef = payload.checkoutRequestId
      ? db
          .collection("checkout_requests")
          .doc(`${uid}_${payload.checkoutRequestId}`)
      : null;

    let promotionRef = null;
    let promotionUserRef = null;
    if (payload.couponCode) {
      const promotionSnap = await db
        .collection("promotions")
        .where("code", "==", payload.couponCode)
        .limit(1)
        .get();
      promotionRef = promotionSnap.empty ? null : promotionSnap.docs[0].ref;
      if (promotionRef) {
        promotionUserRef = promotionRef.collection("users").doc(uid);
      }
    }

    try {
      return await db.runTransaction(async (tx) => {
        const [userSnap, settingsSnap, requestSnap] = await Promise.all([
          tx.get(userRef),
          tx.get(settingsRef),
          requestRef ? tx.get(requestRef) : null,
        ]);
        if (requestSnap?.exists) {
          return requestSnap.data().response;
        }
        if (!userSnap.exists) {
          throw new HttpsError("failed-precondition", "USER_PROFILE_MISSING");
        }

        const user = userSnap.data() || {};
        const role = user.role || user.rule || "customer";
        // الأدمن يمكنه إنشاء طلبات (اختبار/دعم) — السائقون فقط ممنوعون.
        if (role !== "customer" && role !== "admin") {
          throw new HttpsError("permission-denied", "CUSTOMER_ROLE_REQUIRED");
        }
        if (user.isActive === false) {
          throw new HttpsError("permission-denied", "USER_DISABLED");
        }
        assertCustomerMayOrder(user);

        const settings = settingsSnap.data() || {};
        if (settings.maintenanceMode === true) {
          throw new HttpsError("unavailable", "MAINTENANCE_MODE");
        }
        if (user.isGuest === true || isAnonymousAuth(request)) {
          throw new HttpsError("permission-denied", "GUEST_CHECKOUT_DISABLED");
        }

        const storeRefs = payload.orders.map((order) =>
          db.collection("stores").doc(order.storeId),
        );
        const storeSnaps = await Promise.all(storeRefs.map((ref) => tx.get(ref)));

        const productEntries = [];
        payload.orders.forEach((order, orderIndex) => {
          order.lineItems.forEach((line, lineIndex) => {
            productEntries.push({
              orderIndex,
              lineIndex,
              line,
              ref: db
                .collection("stores")
                .doc(order.storeId)
                .collection("products")
                .doc(line.productId),
            });
          });
        });
        const productSnaps = await Promise.all(
          productEntries.map((entry) => tx.get(entry.ref)),
        );

        const [promotionSnap, promotionUserSnap] = await Promise.all([
          promotionRef ? tx.get(promotionRef) : null,
          promotionUserRef ? tx.get(promotionUserRef) : null,
        ]);
        const nowMillis = Date.now();
        const promotion =
          promotionSnap?.exists &&
          activePromotion(promotionSnap.data(), payload, nowMillis)
            ? promotionSnap.data()
            : null;
        if (payload.couponCode && !promotion) {
          throw new HttpsError("failed-precondition", "INVALID_COUPON");
        }
        if (
          promotion &&
          Number(promotion.usageLimit || 0) > 0 &&
          Number(promotion.usageCount || 0) >= Number(promotion.usageLimit)
        ) {
          throw new HttpsError("failed-precondition", "PROMOTION_USAGE_EXHAUSTED");
        }
        if (
          promotion &&
          Number(promotion.perUserLimit || 0) > 0 &&
          Number(promotionUserSnap?.data()?.usageCount || 0) >=
            Number(promotion.perUserLimit)
        ) {
          throw new HttpsError(
            "failed-precondition",
            "PROMOTION_USER_LIMIT_EXHAUSTED",
          );
        }

        const resolvedOrders = payload.orders.map((order, index) => {
          const storeSnap = storeSnaps[index];
          if (!storeSnap.exists) {
            throw new HttpsError("not-found", "STORE_NOT_FOUND");
          }
          const store = storeSnap.data() || {};
          if (!isStoreSellable(store)) {
            throw new HttpsError("failed-precondition", "STORE_UNAVAILABLE");
          }
          if (
            payload.governorate &&
            store.governorate &&
            !sameGovernorate(store.governorate, payload.governorate)
          ) {
            throw new HttpsError("failed-precondition", "STORE_OUT_OF_GOVERNORATE");
          }
          const lines = productEntries
            .map((entry, productIndex) => ({
              ...entry,
              snap: productSnaps[productIndex],
            }))
            .filter((entry) => entry.orderIndex === index)
            .map((entry) => {
              if (!entry.snap.exists) {
                throw new HttpsError("not-found", "PRODUCT_NOT_FOUND");
              }
              try {
                return {
                  ...resolveProductLine(entry.snap.data(), entry.line),
                  productRef: entry.ref,
                  trackStock: entry.snap.data().trackStock === true,
                  previousStock: Number(entry.snap.data().stockQuantity || 0),
                  maxPerCustomer: Number(entry.snap.data().maxPerCustomer || 0),
                  _productData: entry.snap.data(),
                };
              } catch (error) {
                throw new HttpsError(
                  "failed-precondition",
                  error instanceof Error ? error.message : "INVALID_PRODUCT",
                );
              }
            });

          try {
            const productsById = new Map(
              lines.map((line) => [line.productId, line._productData]),
            );
            assertCustomerQuantityLimits(lines, productsById);
          } catch (error) {
            throw new HttpsError(
              "failed-precondition",
              error instanceof Error ? error.message : "CUSTOMER_QUANTITY_LIMIT",
            );
          }

          const subtotal = lines.reduce(
            (sum, line) => sum + line.unitPrice * line.quantity,
            0,
          );
          const minimumOrder = Number(
            store.minOrderAmount ?? settings.minOrderAmount ?? 0,
          );
          if (subtotal < minimumOrder) {
            throw new HttpsError("failed-precondition", "MINIMUM_ORDER_NOT_MET");
          }
          if (
            !paymentAvailableForOrder({
              settings,
              method: payload.paymentMethod,
              store,
              storeId: order.storeId,
              category: order.category,
              governorate: payload.governorate,
              subtotal,
            })
          ) {
            throw new HttpsError(
              "failed-precondition",
              "PAYMENT_METHOD_UNAVAILABLE",
            );
          }

          return {
            store,
            storeRef: storeSnap.ref,
            storeId: order.storeId,
            category: order.category,
            lines,
            subtotal: Number(subtotal.toFixed(2)),
          };
        });

        let pricing;
        try {
          pricing = calculateCheckoutPricing({
            resolvedOrders,
            settings,
            payload,
            promotion,
          });
        } catch (error) {
          throw new HttpsError(
            "failed-precondition",
            error instanceof Error ? error.message : "CHECKOUT_PRICING_FAILED",
          );
        }

        const stockMutations = new Map();
        for (const order of resolvedOrders) {
          for (const line of order.lines) {
            if (!line.trackStock) continue;
            const key = line.productRef.path;
            const current = stockMutations.get(key);
            if (current) {
              current.quantity += line.quantity;
            } else {
              stockMutations.set(key, {
                ref: line.productRef,
                previousStock: line.previousStock,
                quantity: line.quantity,
              });
            }
          }
        }
        for (const mutation of stockMutations.values()) {
          if (mutation.previousStock < mutation.quantity) {
            throw new HttpsError("failed-precondition", "INSUFFICIENT_STOCK");
          }
          tx.update(mutation.ref, {
            stockQuantity: mutation.previousStock - mutation.quantity,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        const created = [];
        for (const order of resolvedOrders) {
          const orderPricing = pricing.orders.find(
            (entry) => entry.storeId === order.storeId,
          );
          if (!orderPricing) {
            throw new HttpsError("internal", "ORDER_PRICING_MISSING");
          }

          const orderRef = db.collection("orders").doc();
          const publicLines = order.lines.map((line) => ({
            productId: line.productId,
            productName: line.productName,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            addonIds: line.addonIds,
            addons: line.addons,
            ...(line.note ? { note: line.note } : {}),
            ...(line.imageUrl ? { imageUrl: line.imageUrl } : {}),
            ...(line.imageThumbUrl
              ? { imageThumbUrl: line.imageThumbUrl }
              : {}),
          }));
          const itemCount = publicLines.reduce(
            (sum, line) => sum + line.quantity,
            0,
          );

          const storeImageRaw =
            order.store.logoUrl ||
            order.store.imageUrl ||
            order.store.imageThumbUrl ||
            "";
          const storeImageUrl =
            typeof storeImageRaw === "string"
              ? storeImageRaw.trim().slice(0, 2000)
              : "";
          const storeRating = Number(order.store.rating || 0);

          tx.create(orderRef, {
            storeId: order.storeId,
            storeName: String(order.store.name || "").slice(0, 160),
            ...(storeImageUrl ? { storeImageUrl } : {}),
            ...(Number.isFinite(storeRating) && storeRating > 0
              ? { storeRating: Number(storeRating.toFixed(1)) }
              : {}),
            ...(order.store.verified === true ? { storeVerified: true } : {}),
            category: payload.orders.find(
              (candidate) => candidate.storeId === order.storeId,
            ).category,
            categoryId:
              order.store.categoryId || order.store.category || "",
            itemsSummary: publicLines
              .map((line) => line.productName)
              .join("، ")
              .slice(0, 500),
            itemCount,
            total: orderPricing.subtotal,
            deliveryFee: orderPricing.deliveryFee,
            rawDeliveryFee: orderPricing.rawDeliveryFee,
            distanceKm: orderPricing.distanceKm,
            etaMinutes: orderPricing.etaMinutes,
            discountAmount: orderPricing.discountAmount,
            serviceFee: orderPricing.serviceFee,
            paymentFee: orderPricing.paymentFee,
            taxes: orderPricing.taxes,
            grandTotal: orderPricing.grandTotal,
            currency: pricing.currency,
            couponCode: promotion ? payload.couponCode : "",
            status: "pending",
            customerId: uid,
            customerName: String(user.name || payload.customerName || "")
              .slice(0, 120),
            governorate:
              payload.governorate ||
              String(user.governorate || "").slice(0, 80),
            phone: String(user.phone || payload.phone || "").slice(0, 32),
            address: payload.address,
            addressFormatted: payload.addressFormatted,
            addressPlaceId: payload.addressPlaceId,
            addressLat: payload.addressLat,
            addressLng: payload.addressLng,
            ...(Number.isFinite(Number(order.store.latitude))
              ? { storeLat: Number(order.store.latitude) }
              : {}),
            ...(Number.isFinite(Number(order.store.longitude))
              ? { storeLng: Number(order.store.longitude) }
              : {}),
            paymentMethod: payload.paymentMethod,
            ...(payload.orderNote ? { orderNote: payload.orderNote } : {}),
            lineItems: publicLines,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            schemaVersion: 2,
          });
          created.push({
            id: orderRef.id,
            storeId: order.storeId,
            total: orderPricing.subtotal,
            deliveryFee: orderPricing.deliveryFee,
            rawDeliveryFee: orderPricing.rawDeliveryFee,
            distanceKm: orderPricing.distanceKm,
            etaMinutes: orderPricing.etaMinutes,
            discountAmount: orderPricing.discountAmount,
            serviceFee: orderPricing.serviceFee,
            paymentFee: orderPricing.paymentFee,
            taxes: orderPricing.taxes,
            grandTotal: orderPricing.grandTotal,
          });
        }

        if (promotionRef) {
          tx.set(
            promotionRef,
            {
              usageCount: FieldValue.increment(1),
              lastUsedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          tx.set(
            promotionUserRef,
            {
              usageCount: FieldValue.increment(1),
              lastUsedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }

        tx.set(
          userRef,
          {
            lastOrderAt: FieldValue.serverTimestamp(),
            lastPaymentMethod: payload.paymentMethod,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        const response = {
          orderIds: created.map((order) => order.id),
          orders: created,
          pricing: publicPricing(pricing),
          createdAt: Timestamp.now().toMillis(),
        };
        if (requestRef) {
          tx.create(requestRef, {
            customerId: uid,
            response,
            createdAt: FieldValue.serverTimestamp(),
            expiresAt: Timestamp.fromMillis(
              Date.now() + 24 * 60 * 60 * 1000,
            ),
          });
        }
        return response;
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "ORDER_CREATE_FAILED");
    }
  },
);

/**
 * Read-only checkout preview. Uses the exact same authoritative product,
 * promotion, delivery and fee calculator as order creation.
 */
const previewCustomerCheckout = onCall(
  {
    region: FUNCTIONS_REGION,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "يجب تسجيل الدخول لإتمام الطلب.");
    }

    let payload;
    try {
      payload = normalizeCheckoutPayload(request.data);
    } catch (error) {
      throw invalidArgument(error);
    }

    const db = getFirestore();
    const uid = request.auth.uid;
    await checkRateLimit(db, `checkout-preview:${uid}`, 30, 60 * 1000);

    const [userSnap, settingsSnap] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("app_settings").doc("config").get(),
    ]);
    if (!userSnap.exists) {
      throw new HttpsError("failed-precondition", "USER_PROFILE_MISSING");
    }
    const user = userSnap.data() || {};
    const role = user.role || user.rule || "customer";
    if (role !== "customer" && role !== "admin") {
      throw new HttpsError("permission-denied", "CUSTOMER_ROLE_REQUIRED");
    }
    if (user.isActive === false) {
      throw new HttpsError("permission-denied", "USER_DISABLED");
    }
    assertCustomerMayOrder(user);
    const settings = settingsSnap.data() || {};
    if (settings.maintenanceMode === true) {
      throw new HttpsError("unavailable", "MAINTENANCE_MODE");
    }
    if (user.isGuest === true || isAnonymousAuth(request)) {
      throw new HttpsError("permission-denied", "GUEST_CHECKOUT_DISABLED");
    }

    let promotion = null;
    if (payload.couponCode) {
      const snap = await db
        .collection("promotions")
        .where("code", "==", payload.couponCode)
        .limit(1)
        .get();
      if (snap.empty || !activePromotion(snap.docs[0].data(), payload, Date.now())) {
        throw new HttpsError("failed-precondition", "INVALID_COUPON");
      }
      promotion = snap.docs[0].data();
      if (
        Number(promotion.usageLimit || 0) > 0 &&
        Number(promotion.usageCount || 0) >= Number(promotion.usageLimit)
      ) {
        throw new HttpsError("failed-precondition", "PROMOTION_USAGE_EXHAUSTED");
      }
      if (Number(promotion.perUserLimit || 0) > 0) {
        const usageSnap = await snap.docs[0].ref.collection("users").doc(uid).get();
        if (
          Number(usageSnap.data()?.usageCount || 0) >=
          Number(promotion.perUserLimit)
        ) {
          throw new HttpsError(
            "failed-precondition",
            "PROMOTION_USER_LIMIT_EXHAUSTED",
          );
        }
      }
    }

    const storeRefs = payload.orders.map((order) =>
      db.collection("stores").doc(order.storeId),
    );
    const storeSnaps = await db.getAll(...storeRefs);
    const productEntries = [];
    payload.orders.forEach((order, orderIndex) => {
      order.lineItems.forEach((line) => {
        productEntries.push({
          orderIndex,
          line,
          ref: db
            .collection("stores")
            .doc(order.storeId)
            .collection("products")
            .doc(line.productId),
        });
      });
    });
    const productSnaps = await db.getAll(
      ...productEntries.map((entry) => entry.ref),
    );

    const resolvedOrders = payload.orders.map((order, index) => {
      const storeSnap = storeSnaps[index];
      if (!storeSnap.exists) {
        throw new HttpsError("not-found", "STORE_NOT_FOUND");
      }
      const store = storeSnap.data() || {};
      if (!isStoreSellable(store)) {
        throw new HttpsError("failed-precondition", "STORE_UNAVAILABLE");
      }
      if (
        payload.governorate &&
        store.governorate &&
        !sameGovernorate(store.governorate, payload.governorate)
      ) {
        throw new HttpsError("failed-precondition", "STORE_OUT_OF_GOVERNORATE");
      }
      const lines = productEntries
        .map((entry, productIndex) => ({
          ...entry,
          snap: productSnaps[productIndex],
        }))
        .filter((entry) => entry.orderIndex === index)
        .map((entry) => {
          if (!entry.snap.exists) {
            throw new HttpsError("not-found", "PRODUCT_NOT_FOUND");
          }
          try {
            return {
              ...resolveProductLine(entry.snap.data(), entry.line),
              _productData: entry.snap.data(),
            };
          } catch (error) {
            throw new HttpsError(
              "failed-precondition",
              error instanceof Error ? error.message : "INVALID_PRODUCT",
            );
          }
        });
      try {
        const productsById = new Map(
          lines.map((line) => [line.productId, line._productData]),
        );
        assertCustomerQuantityLimits(lines, productsById);
      } catch (error) {
        throw new HttpsError(
          "failed-precondition",
          error instanceof Error ? error.message : "CUSTOMER_QUANTITY_LIMIT",
        );
      }
      const subtotal = Number(
        lines
          .reduce((sum, line) => sum + line.unitPrice * line.quantity, 0)
          .toFixed(2),
      );
      const minimumOrder = Number(
        store.minOrderAmount ?? settings.minOrderAmount ?? 0,
      );
      if (subtotal < minimumOrder) {
        throw new HttpsError("failed-precondition", "MINIMUM_ORDER_NOT_MET");
      }
      if (
        !paymentAvailableForOrder({
          settings,
          method: payload.paymentMethod,
          store,
          storeId: order.storeId,
          category: order.category,
          governorate: payload.governorate,
          subtotal,
        })
      ) {
        throw new HttpsError(
          "failed-precondition",
          "PAYMENT_METHOD_UNAVAILABLE",
        );
      }
      return {
        store,
        storeId: order.storeId,
        category: order.category,
        lines,
        subtotal,
      };
    });

    try {
      const pricing = calculateCheckoutPricing({
        resolvedOrders,
        settings,
        payload,
        promotion,
      });
      return {
        pricing: publicPricing(pricing),
        orders: resolvedOrders.map((order) => ({
          storeId: order.storeId,
          storeName: String(order.store.name || ""),
          lineItems: order.lines,
        })),
        availablePaymentMethods: (
          Array.isArray(settings.checkoutPaymentMethods) &&
          settings.checkoutPaymentMethods.length > 0
            ? settings.checkoutPaymentMethods
                .filter((method) => method?.isActive === true)
                .map((method) => String(method.id || ""))
                .filter(Boolean)
            : ["cash"]
        ).filter((method) =>
          resolvedOrders.every((order) =>
            paymentAvailableForOrder({
              settings,
              method,
              store: order.store,
              storeId: order.storeId,
              category: order.category,
              governorate: payload.governorate,
              subtotal: order.subtotal,
            }),
          ),
        ),
        calculatedAt: Timestamp.now().toMillis(),
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "failed-precondition",
        error instanceof Error ? error.message : "CHECKOUT_PRICING_FAILED",
      );
    }
  },
);

module.exports = { createCustomerOrders, previewCustomerCheckout };
