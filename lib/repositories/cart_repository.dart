import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/cart_coupon_preview.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/cart_service.dart';

/// طبقة مستودع السلة — واجهة مستقرة للـ UI.
/// التنفيذ الحالي يفوّض إلى [CartService] مع إمكانية استبدال التخزين لاحقاً.
class CartRepository {
  CartRepository({
    CartService? service,
    FirebaseFunctions? functions,
  }) : _service = service ?? CartService.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final CartService _service;
  final FirebaseFunctions _functions;

  static final CartRepository instance = CartRepository();

  CartService get service => _service;

  List<CartItem> get items => _service.items;
  int get itemCount => _service.itemCount;
  double get subtotal => _service.subtotal;
  bool get isEmpty => _service.isEmpty;
  String get orderNote => _service.orderNote;
  CartCouponPreview? get appliedCoupon => _service.appliedCoupon;

  void addListener(VoidCallback listener) => _service.addListener(listener);
  void removeListener(VoidCallback listener) =>
      _service.removeListener(listener);

  void setOrderNote(String note) => _service.setOrderNote(note);

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
    return _service.addProduct(
      store: store,
      product: product,
      quantity: quantity,
      unitPrice: unitPrice,
      displayName: displayName,
      cartLineId: cartLineId,
      addonIds: addonIds,
      note: note,
    );
  }

  void updateQuantity(String itemId, int quantity) =>
      _service.updateQuantity(itemId, quantity);

  void removeItem(String itemId, {String screen = 'cart'}) =>
      _service.removeItem(itemId, screen: screen);

  void clear() => _service.clear();

  String? validateStoreMinOrders() => _service.validateStoreMinOrders();

  String? validateDeliveryAddress(DeliveryAddress? address) =>
      _service.validateDeliveryAddress(address);

  /// معاينة كوبون خادمية بدون عنوان توصيل.
  Future<CartCouponPreview> validateCoupon({
    required String couponCode,
    required String governorate,
    Set<String>? storeIds,
    Set<String>? categoryIds,
    Set<String>? productIds,
    double? subtotal,
  }) async {
    final effectiveStoreIds =
        storeIds ?? _service.items.map((item) => item.storeId).toSet();
    final effectiveCategoryIds =
        categoryIds ??
        _service.items.map((item) => item.category).toSet();
    final effectiveProductIds =
        productIds ?? _service.items.map((item) => item.productId).toSet();
    final result = await _functions
        .httpsCallable(
          'validateCartCoupon',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
        )
        .call({
          'couponCode': couponCode.trim().toUpperCase(),
          'governorate': governorate,
          'storeIds': effectiveStoreIds.toList(),
          'categoryIds': effectiveCategoryIds.toList(),
          'productIds': effectiveProductIds.toList(),
          'subtotal': subtotal ?? _service.subtotal,
        });
    final raw = result.data;
    if (raw is! Map) {
      throw StateError('Invalid validateCartCoupon response');
    }
    final preview = CartCouponPreview.fromCallable(
      Map<String, dynamic>.from(raw),
    );
    if (preview.valid) {
      _service.applyCouponPreview(preview);
    } else {
      _service.clearCouponPreview();
    }
    return preview;
  }

  void clearCoupon() => _service.clearCouponPreview();

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
    return _service.buildCheckoutDrafts(
      governorate: governorate,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      address: address,
      couponCode: couponCode ?? _service.appliedCoupon?.code,
      paymentMethod: paymentMethod,
    );
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
    return _service.previewCheckout(
      governorate: governorate,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      couponCode: couponCode ?? _service.appliedCoupon?.code,
      paymentMethod: paymentMethod,
    );
  }
}
