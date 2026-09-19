import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/cart_coupon_preview.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/order_line_item.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/services/delivery_address_session.dart';
import 'package:matlobgo/services/delivery_pricing_service.dart';
import 'package:matlobgo/services/order_service.dart';

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];
  String _orderNote = '';
  CartCouponPreview? _appliedCoupon;

  List<CartItem> get items => List.unmodifiable(_items);

  String get orderNote => _orderNote;

  CartCouponPreview? get appliedCoupon => _appliedCoupon;

  double get previewDiscountAmount => _appliedCoupon?.discountAmount ?? 0;

  double get cartTotalPreview {
    final discounted = (subtotal - previewDiscountAmount).clamp(0, double.infinity);
    return discounted.toDouble();
  }

  void setOrderNote(String note) {
    final normalized = note.trim();
    if (_orderNote == normalized) return;
    _orderNote = normalized;
    notifyListeners();
  }

  void applyCouponPreview(CartCouponPreview preview) {
    _appliedCoupon = preview;
    notifyListeners();
  }

  void clearCouponPreview() {
    if (_appliedCoupon == null) return;
    _appliedCoupon = null;
    notifyListeners();
  }

  int get itemCount => _items.fold(0, (total, item) => total + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  double get deliveryFee {
    if (_items.isEmpty) return 0;
    final quote = DeliveryAddressSession.instance.quote;
    if (quote != null) {
      if (!quote.isInZone) return 0;
      return quote.fee;
    }
    final settings = AppConfigService.instance.settings;
    final storeCount = settings.storeCountFromItems(
      _items.map((e) => e.storeId),
    );
    return settings.computeDeliveryFee(
      subtotal: subtotal,
      storeCount: storeCount,
    );
  }

  double get rawDeliveryFee {
    if (_items.isEmpty) return 0;
    final quote = DeliveryAddressSession.instance.quote;
    if (quote != null && quote.rawFee > 0) return quote.rawFee;
    return deliveryFee;
  }

  double? get deliveryDistanceKm =>
      DeliveryAddressSession.instance.quote?.distanceKm;

  bool get isDeliveryAvailable {
    final quote = DeliveryAddressSession.instance.quote;
    if (quote == null) return true;
    return quote.isInZone;
  }

  String? get deliveryBlockedMessage =>
      DeliveryAddressSession.instance.quote?.outOfZoneMessage;

  bool get hasFreeDelivery =>
      AppConfigService.instance.settings.qualifiesForFreeDelivery(subtotal);

  double? get freeDeliveryRemaining =>
      AppConfigService.instance.settings.freeDeliveryRemaining(subtotal);

  double get total => subtotal + deliveryFee;

  bool get isEmpty => _items.isEmpty;

  /// يتحقق من الحد الأدنى لكل متجر في السلة.
  String? validateStoreMinOrders() {
    if (_items.isEmpty) return null;
    final settings = AppConfigService.instance.settings;
    final subtotals = <String, double>{};
    final mins = <String, double>{};
    final names = <String, String>{};

    for (final item in _items) {
      subtotals[item.storeId] = (subtotals[item.storeId] ?? 0) + item.lineTotal;
      mins[item.storeId] = item.storeMinOrderAmount > 0
          ? item.storeMinOrderAmount
          : settings.minOrderAmount;
      names[item.storeId] = item.storeName;
    }

    for (final entry in subtotals.entries) {
      final min = mins[entry.key] ?? settings.minOrderAmount;
      if (entry.value < min) {
        return 'الحد الأدنى لـ ${names[entry.key]} هو ${min.toInt()} ج.م';
      }
    }
    return null;
  }

  /// يضيف منتجاً للسلة إن كان المتجر قابلاً للطلب (`isSellable`).
  /// يرجع `false` إذا كان المتجر مغلقاً / خارج ساعات العمل.
  bool addProduct({
    required Store store,
    required Product product,
    int quantity = 1,
    double? unitPrice,
    String? displayName,
    String? cartLineId,
    List<String> addonIds = const [],
    String note = '',
  }) {
    if (!store.isSellable) return false;
    final lineId = cartLineId ?? '${store.id}_${product.id}';
    final maxQty = product.maxOrderQuantity;
    if (maxQty <= 0) return false;

    final usedElsewhere = _items
        .where(
          (item) =>
              item.storeId == store.id &&
              item.productId == product.id &&
              item.id != lineId,
        )
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final remaining = maxQty - usedElsewhere;
    if (remaining <= 0) return false;

    final existing = _items.where((item) => item.id == lineId);
    if (existing.isNotEmpty) {
      final item = existing.first;
      final next = (item.quantity + quantity).clamp(1, remaining);
      if (next == item.quantity) return false;
      item.quantity = next;
      item.trackStock = product.trackStock;
      item.stockQuantity = product.stockQuantity;
      item.maxPerCustomer = product.maxPerCustomer;
    } else {
      _items.add(
        CartItem(
          id: lineId,
          storeId: store.id,
          productId: product.id,
          storeName: store.name,
          category: store.categoryId,
          productName: displayName ?? product.name,
          price: unitPrice ?? product.price,
          quantity: quantity.clamp(1, remaining),
          imageUrl: product.imageUrl,
          imageThumbUrl: product.imageThumbUrl,
          storeMinOrderAmount: store.minOrderAmount,
          addonIds: List.unmodifiable(addonIds),
          note: note.trim(),
          trackStock: product.trackStock,
          stockQuantity: product.stockQuantity,
          maxPerCustomer: product.maxPerCustomer,
          isAvailable: product.isInStock,
          discountPercent: product.effectiveDiscountPercent,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId, screen: 'cart');
      return;
    }
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final item = _items[index];
    final usedElsewhere = _items
        .where(
          (other) =>
              other.storeId == item.storeId &&
              other.productId == item.productId &&
              other.id != itemId,
        )
        .fold<int>(0, (sum, other) => sum + other.quantity);
    final remaining = item.maxOrderQuantity - usedElsewhere;
    item.quantity = quantity.clamp(1, remaining <= 0 ? 1 : remaining);
    notifyListeners();
  }

  /// يحدّث بيانات السطر من Firestore (سعر/مخزون/توفر) دون تغيير الهوية.
  void syncItemSnapshot(
    String itemId, {
    required double price,
    required String productName,
    String? imageUrl,
    String? imageThumbUrl,
    double? storeMinOrderAmount,
    required bool isAvailable,
    required bool trackStock,
    int? stockQuantity,
    int maxPerCustomer = 0,
    double discountPercent = 0,
  }) {
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final item = _items[index];
    final nextMax = CartItem(
      id: item.id,
      storeId: item.storeId,
      productId: item.productId,
      storeName: item.storeName,
      category: item.category,
      productName: productName,
      price: price,
      quantity: item.quantity,
      imageUrl: imageUrl ?? item.imageUrl,
      imageThumbUrl: imageThumbUrl ?? item.imageThumbUrl,
      storeMinOrderAmount: storeMinOrderAmount ?? item.storeMinOrderAmount,
      addonIds: item.addonIds,
      note: item.note,
      isAvailable: isAvailable,
      trackStock: trackStock,
      stockQuantity: stockQuantity,
      maxPerCustomer: maxPerCustomer,
      discountPercent: discountPercent,
    ).maxOrderQuantity;
    final clampedQty = item.quantity.clamp(1, nextMax == 0 ? 1 : nextMax);

    var changed = false;
    if ((item.price - price).abs() > 0.001) {
      item.price = price;
      changed = true;
    }
    if (item.productName != productName) {
      _items[index] = item.copyWith(
        price: price,
        productName: productName,
        imageUrl: imageUrl,
        imageThumbUrl: imageThumbUrl,
        storeMinOrderAmount: storeMinOrderAmount,
        isAvailable: isAvailable,
        trackStock: trackStock,
        stockQuantity: stockQuantity,
        maxPerCustomer: maxPerCustomer,
        discountPercent: discountPercent,
        quantity: clampedQty,
      );
      notifyListeners();
      return;
    }
    if (item.isAvailable != isAvailable) {
      item.isAvailable = isAvailable;
      changed = true;
    }
    if (item.trackStock != trackStock) {
      item.trackStock = trackStock;
      changed = true;
    }
    if (item.stockQuantity != stockQuantity) {
      item.stockQuantity = stockQuantity;
      changed = true;
    }
    if (item.maxPerCustomer != maxPerCustomer) {
      item.maxPerCustomer = maxPerCustomer;
      changed = true;
    }
    if ((item.discountPercent - discountPercent).abs() > 0.01) {
      item.discountPercent = discountPercent;
      changed = true;
    }
    if (storeMinOrderAmount != null &&
        (item.storeMinOrderAmount - storeMinOrderAmount).abs() > 0.01) {
      item.storeMinOrderAmount = storeMinOrderAmount;
      changed = true;
    }
    if (item.quantity != clampedQty) {
      item.quantity = clampedQty;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void removeItem(String itemId, {String screen = 'cart'}) {
    final item = _items.where((e) => e.id == itemId).firstOrNull;
    if (item != null) {
      unawaited(
        AnalyticsService.instance.removeFromCart(
          screen: screen,
          productName: item.productName,
          storeId: item.storeId,
          storeName: item.storeName,
          productId: item.productId,
          quantity: item.quantity,
        ),
      );
    }
    _items.removeWhere((e) => e.id == itemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _orderNote = '';
    _appliedCoupon = null;
    notifyListeners();
  }

  /// يعيد منتجاً محذوفاً (Undo بعد السحب).
  void restoreItem(CartItem item) {
    if (_items.any((e) => e.id == item.id)) return;
    _items.add(item);
    notifyListeners();
  }

  String? validateDeliveryAddress(DeliveryAddress? address) {
    if (address == null || !address.hasCoordinates) {
      return 'حدّد عنوان توصيل صالح من الخريطة أو البحث';
    }
    final quote = DeliveryAddressSession.instance.quote;
    if (quote != null && !quote.isInZone) {
      return quote.outOfZoneMessage.isNotEmpty
          ? quote.outOfZoneMessage
          : DeliveryQuote.outOfZoneMessageDefault;
    }
    if (address.outOfZone) {
      return DeliveryQuote.outOfZoneMessageDefault;
    }
    return null;
  }

  Future<List<Order>> checkout({
    required String governorate,
    required String customerId,
    required String customerName,
    String? phone,
    DeliveryAddress? deliveryAddress,
    String? address,
    String? couponCode,
    double discountAmount = 0,
    String paymentMethod = 'cash',
    String? checkoutRequestId,
  }) async {
    final drafts = buildCheckoutDrafts(
      governorate: governorate,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      address: address,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
    );
    if (drafts.isEmpty) return [];
    final placed = await OrderService.instance.placeOrders(
      drafts,
      checkoutRequestId: checkoutRequestId,
    );
    clear();
    return placed;
  }

  List<Order> buildCheckoutDrafts({
    required String governorate,
    required String customerId,
    required String customerName,
    String? phone,
    DeliveryAddress? deliveryAddress,
    String? address,
    String? couponCode,
    String paymentMethod = 'cash',
  }) {
    if (_items.isEmpty) return const [];
    final addrError = validateDeliveryAddress(deliveryAddress);
    if (addrError != null) throw StateError(addrError);
    final grouped = <String, List<CartItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.storeId, () => []).add(item);
    }
    return grouped.entries.map((entry) {
      final storeItems = entry.value;
      final storeName = storeItems.first.storeName;
      final category = storeItems.first.category;
      final storeId = entry.key;
      final summary = storeItems.map((e) => e.productName).join('، ');
      final count = storeItems.fold(0, (sum, e) => sum + e.quantity);
      final lineItems = storeItems
          .map(
            (e) => OrderLineItem(
              productId: e.productId,
              productName: e.productName,
              quantity: e.quantity,
              unitPrice: e.price,
              addonIds: e.addonIds,
              note: e.note,
              imageUrl: e.imageUrl?.trim() ?? '',
              imageThumbUrl: e.imageThumbUrl?.trim() ?? e.imageUrl?.trim() ?? '',
            ),
          )
          .toList();

      return Order(
        id: '',
        storeId: storeId,
        storeName: storeName,
        category: category,
        itemsSummary: summary,
        itemCount: count,
        // Monetary fields are intentionally zero in client drafts. The server
        // resolves prices and returns the authoritative values.
        total: 0,
        deliveryFee: 0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        customerId: customerId,
        customerName: customerName,
        governorate: governorate,
        phone: phone,
        address: deliveryAddress?.legacyAddressText ?? address,
        addressLat: deliveryAddress?.latitude,
        addressLng: deliveryAddress?.longitude,
        addressPlaceId: deliveryAddress?.placeId,
        addressFormatted: deliveryAddress?.formattedAddress,
        lineItems: lineItems,
        couponCode: couponCode,
        discountAmount: 0,
        paymentMethod: paymentMethod,
        orderNote: _orderNote,
      );
    }).toList();
  }

  Future<CheckoutQuote> previewCheckout({
    required String governorate,
    required String customerId,
    required String customerName,
    String? phone,
    required DeliveryAddress deliveryAddress,
    String? couponCode,
    String paymentMethod = 'cash',
  }) {
    final drafts = buildCheckoutDrafts(
      governorate: governorate,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
    );
    return OrderService.instance.previewCheckout(drafts);
  }
}
