import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/cart_coupon_preview.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/cart_repository.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/screens/home/checkout/checkout_error_message.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/order_service.dart';

/// حالة شاشة السلة — UI يعتمد عليها فقط (لا CartService مباشرة).
class CartController extends ChangeNotifier {
  CartController({
    required this.governorateName,
    CartRepository? repository,
    AppConfigService? config,
    ProductRepository? products,
    StoreRepository? stores,
    OrderService? orders,
  }) : _repo = repository ?? CartRepository.instance,
       _config = config ?? AppConfigService.instance,
       _productRepo = products ?? ProductRepository(),
       _storeRepo = stores ?? StoreRepository(),
       _orders = orders ?? OrderService.instance {
    _repo.addListener(_onCartChanged);
    _config.addListener(_onConfigChanged);
    _itemsSignature = _computeItemsSignature();
    _bindRealtime();
    unawaited(_loadSuggestions());
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.cartOpen,
        screen: 'cart',
        label: 'فتح السلة',
        metadata: {'itemCount': itemCount},
      ),
    );
  }

  final String governorateName;
  final CartRepository _repo;
  final AppConfigService _config;
  final ProductRepository _productRepo;
  final StoreRepository _storeRepo;
  final OrderService _orders;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String _realtimeSignature = '';
  String _itemsSignature = '';
  String? _notice;
  String? _error;
  bool _couponBusy = false;
  bool _suggestionsLoading = false;
  bool _offline = false;
  bool _syncingRealtime = false;
  List<Product> _suggestions = const [];
  final Map<String, Store> _storesById = {};
  /// آخر حالة توفر معروفة للمنتج (بدون اعتبار حالة المتجر).
  final Map<String, bool> _productInStockByKey = {};
  bool _freeDeliveryUnlockedTracked = false;
  Timer? _suggestionsDebounce;
  int _suggestionsGeneration = 0;

  CartRepository get repository => _repo;
  List<CartItem> get items => _repo.items;
  int get itemCount => _repo.itemCount;
  double get subtotal => _repo.subtotal;
  bool get isEmpty => _repo.isEmpty;
  String get orderNote => _repo.orderNote;
  CartCouponPreview? get appliedCoupon => _repo.appliedCoupon;
  String? get notice => _notice;
  String? get error => _error;
  bool get offline => _offline;
  bool get couponBusy => _couponBusy;
  bool get suggestionsLoading => _suggestionsLoading;
  List<Product> get suggestions => _suggestions;
  AppSettings get settings => _config.settings;
  bool get suggestionsEnabled => settings.cartUi.suggestionsEnabled;
  bool get freeDeliveryEnabled => settings.cartUi.freeDeliveryProgressEnabled;

  double get discountAmount => appliedCoupon?.discountAmount ?? 0;

  double get currentTotal =>
      (subtotal - discountAmount).clamp(0, double.infinity).toDouble();

  double? get freeDeliveryRemaining {
    if (!freeDeliveryEnabled) return null;
    return settings.freeDeliveryRemaining(subtotal);
  }

  bool get hasFreeDelivery =>
      freeDeliveryEnabled && settings.qualifiesForFreeDelivery(subtotal);

  double get freeDeliveryProgress {
    final threshold = settings.freeDeliveryThreshold;
    if (threshold <= 0) return 1;
    return (subtotal / threshold).clamp(0, 1).toDouble();
  }

  void clearNotice() {
    if (_notice == null && _error == null) return;
    _notice = null;
    _error = null;
    notifyListeners();
  }

  void setOrderNote(String note) => _repo.setOrderNote(note);

  Future<void> updateQuantity(String itemId, int quantity) async {
    final before = items.where((e) => e.id == itemId).firstOrNull;
    if (before == null) return;
    final usedElsewhere = items
        .where(
          (other) =>
              other.storeId == before.storeId &&
              other.productId == before.productId &&
              other.id != itemId,
        )
        .fold<int>(0, (total, other) => total + other.quantity);
    final maxQty = before.maxOrderQuantity - usedElsewhere;
    if (quantity > maxQty) {
      _error = before.maxPerCustomer > 0 &&
              (!before.trackStock ||
                  before.stockQuantity == null ||
                  before.maxPerCustomer <= (before.stockQuantity ?? 99))
          ? 'وصلت للحد الأقصى المسموح لهذا المنتج'
          : 'وصلت للحد الأقصى المتاح من المخزون';
      notifyListeners();
      return;
    }
    _repo.updateQuantity(itemId, quantity);
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.cartQuantityChange,
        screen: 'cart',
        label: 'تعديل كمية',
        productId: before.productId,
        productName: before.productName,
        storeId: before.storeId,
        metadata: {'quantity': quantity},
      ),
    );
  }

  CartItem? removeItem(String itemId, {bool swipe = false}) {
    final item = items.where((e) => e.id == itemId).firstOrNull;
    if (item == null) return null;
    _repo.removeItem(itemId);
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.removeFromCart,
        screen: 'cart',
        label: swipe ? 'حذف بالسحب' : 'حذف منتج',
        productId: item.productId,
        productName: item.productName,
        storeId: item.storeId,
        metadata: {'swipe': swipe},
      ),
    );
    return item;
  }

  void restoreItem(CartItem item) {
    _repo.service.restoreItem(item);
  }

  void clearAll() {
    _repo.clear();
    _suggestions = const [];
    notifyListeners();
  }

  Future<void> applyCoupon(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _couponBusy) return;
    _couponBusy = true;
    _error = null;
    notifyListeners();
    try {
      final preview = await _repo.validateCoupon(
        couponCode: trimmed,
        governorate: governorateName,
      );
      if (!preview.valid) {
        _error = preview.message.isNotEmpty
            ? preview.message
            : checkoutErrorMessage(
                FirebaseFunctionsException(
                  code: 'failed-precondition',
                  message: preview.rejectionCode,
                ),
              );
      } else {
        _notice = null;
        _offline = false;
        unawaited(
          AnalyticsService.instance.track(
            type: AnalyticsEventType.applyCoupon,
            screen: 'cart',
            label: 'تطبيق كوبون',
            metadata: {
              'code': preview.code,
              'discount': preview.discountAmount,
            },
          ),
        );
      }
    } catch (error) {
      _error = checkoutErrorMessage(error);
      _repo.clearCoupon();
      if (_isNetworkError(error)) {
        _offline = true;
      }
    } finally {
      _couponBusy = false;
      notifyListeners();
    }
  }

  void removeCoupon() {
    _repo.clearCoupon();
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.removeCoupon,
        screen: 'cart',
        label: 'إزالة كوبون',
      ),
    );
    notifyListeners();
  }

  Future<void> addSuggestion(Product product) async {
    Store? store = _storesById[product.storeId];
    store ??= await _storeRepo.getStore(product.storeId);
    if (store == null) {
      _error = 'تعذّر إضافة المنتج — المتجر غير متاح';
      notifyListeners();
      return;
    }
    if (!_storeIsSellable(store)) {
      _error = 'المتجر مغلق حالياً — لا يمكن إضافة منتجات منه';
      notifyListeners();
      return;
    }
    _storesById[store.id] = store;
    _repo.addProduct(store: store, product: product, quantity: 1);
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.addSuggestionToCart,
        screen: 'cart',
        label: 'إضافة من المقترحات',
        productId: product.id,
        productName: product.name,
        storeId: store.id,
      ),
    );
  }

  Store? storeFor(String storeId) => _storesById[storeId];

  /// أقصى كمية لهذا السطر بعد احتساب باقي أسطر نفس المنتج.
  int maxQuantityFor(CartItem item) {
    final usedElsewhere = items
        .where(
          (other) =>
              other.storeId == item.storeId &&
              other.productId == item.productId &&
              other.id != item.id,
        )
        .fold<int>(0, (total, other) => total + other.quantity);
    final remaining = item.maxOrderQuantity - usedElsewhere;
    return remaining < 1 ? 1 : remaining;
  }

  String? validateBeforeCheckout() {
    if (isEmpty) return 'سلتك فارغة — أضف منتجات أولاً';
    if (_offline) {
      return 'الاتصال ضعيف — تحقق من الشبكة ثم أعد المحاولة';
    }
    final unavailable = items.where((item) => !item.isAvailable).toList();
    if (unavailable.isNotEmpty) {
      return 'بعض المنتجات لم تعد متاحة — أزلها من السلة';
    }
    for (final storeId in items.map((e) => e.storeId).toSet()) {
      final store = _storesById[storeId];
      if (store != null && !_storeIsSellable(store)) {
        return 'متجر «${store.name}» مغلق حالياً — عدّل سلتك';
      }
    }
    final stockBlocked = items.where((item) {
      final used = items
          .where(
            (other) =>
                other.storeId == item.storeId &&
                other.productId == item.productId,
          )
          .fold<int>(0, (total, other) => total + other.quantity);
      if (item.maxOrderQuantity <= 0) return true;
      return used > item.maxOrderQuantity;
    }).toList();
    if (stockBlocked.isNotEmpty) {
      return 'بعض المنتجات تجاوزت الكمية المسموحة';
    }
    return _repo.validateStoreMinOrders();
  }

  String _computeItemsSignature() {
    final parts = items.map((e) => '${e.storeId}/${e.productId}').toList()
      ..sort();
    return parts.join('|');
  }

  void _onCartChanged() {
    if (_syncingRealtime) {
      // تحديثات السعر/المخزون من الـ listeners — لا تعيد تحميل المقترحات.
      if (hasFreeDelivery && !_freeDeliveryUnlockedTracked) {
        _freeDeliveryUnlockedTracked = true;
        unawaited(
          AnalyticsService.instance.track(
            type: AnalyticsEventType.freeDeliveryUnlocked,
            screen: 'cart',
            label: 'الوصول للتوصيل المجاني',
            metadata: {'subtotal': subtotal},
          ),
        );
      } else if (!hasFreeDelivery) {
        _freeDeliveryUnlockedTracked = false;
      }
      notifyListeners();
      return;
    }

    final nextSignature = _computeItemsSignature();
    final compositionChanged = nextSignature != _itemsSignature;
    _itemsSignature = nextSignature;

    if (hasFreeDelivery && !_freeDeliveryUnlockedTracked) {
      _freeDeliveryUnlockedTracked = true;
      unawaited(
        AnalyticsService.instance.track(
          type: AnalyticsEventType.freeDeliveryUnlocked,
          screen: 'cart',
          label: 'الوصول للتوصيل المجاني',
          metadata: {'subtotal': subtotal},
        ),
      );
    } else if (!hasFreeDelivery) {
      _freeDeliveryUnlockedTracked = false;
    }

    // كوبون السلة معاينة فقط — أعد التحقق عند تغيّر التركيبة أو المجموع.
    if (appliedCoupon != null) {
      unawaited(_revalidateAppliedCoupon());
    }

    if (compositionChanged) {
      _bindRealtime();
      _scheduleSuggestionsReload();
    }
    notifyListeners();
  }

  Future<void> _revalidateAppliedCoupon() async {
    final code = appliedCoupon?.code;
    if (code == null || code.isEmpty || isEmpty) {
      _repo.clearCoupon();
      return;
    }
    try {
      final preview = await _repo.validateCoupon(
        couponCode: code,
        governorate: governorateName,
      );
      if (!preview.valid) {
        _repo.clearCoupon();
        _notice = preview.message.isNotEmpty
            ? preview.message
            : 'تم إلغاء الكوبون لأن شروطه لم تعد متوفرة';
        notifyListeners();
      }
    } catch (_) {
      // أبقِ المعاينة السابقة عند فشل الشبكة؛ Checkout يعيد التحقق نهائياً.
    }
  }

  void _onConfigChanged() {
    notifyListeners();
    _scheduleSuggestionsReload();
  }

  void _scheduleSuggestionsReload() {
    _suggestionsDebounce?.cancel();
    _suggestionsDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadSuggestions,
    );
  }

  void _bindRealtime() {
    final key = _computeItemsSignature();
    if (key == _realtimeSignature) return;
    _realtimeSignature = key;
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    if (items.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final storeIds = items.map((e) => e.storeId).toSet().toList();
    for (final chunk in _chunks(storeIds, 30)) {
      _subscriptions.add(
        firestore
            .collection('stores')
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .listen(
              (snap) {
                _offline = false;
                for (final doc in snap.docs) {
                  _storesById[doc.id] = Store.fromFirestore(doc);
                }
                _applyStoreStatus();
                notifyListeners();
              },
              onError: (_) {
                _offline = true;
                _error = 'تعذّر تحديث بيانات المتاجر — تحقق من الاتصال';
                notifyListeners();
              },
            ),
      );
    }

    final byStore = <String, Set<String>>{};
    for (final item in items) {
      byStore.putIfAbsent(item.storeId, () => <String>{}).add(item.productId);
    }
    for (final entry in byStore.entries) {
      for (final chunk in _chunks(entry.value.toList(), 30)) {
        _subscriptions.add(
          firestore
              .collection('stores')
              .doc(entry.key)
              .collection('products')
              .where(FieldPath.documentId, whereIn: chunk)
              .snapshots()
              .listen(
                (snap) => _onProductsSnapshot(entry.key, snap, chunk.toSet()),
                onError: (_) {
                  _offline = true;
                  _error = 'تعذّر تحديث المنتجات — تحقق من الاتصال';
                  notifyListeners();
                },
              ),
        );
      }
    }
  }

  void _onProductsSnapshot(
    String storeId,
    QuerySnapshot<Map<String, dynamic>> snap,
    Set<String> requestedIds,
  ) {
    var priceChanged = false;
    var availabilityChanged = false;
    final existingIds = snap.docs.map((d) => d.id).toSet();

    _syncingRealtime = true;
    try {
      for (final productId in requestedIds) {
        if (existingIds.contains(productId)) continue;
        for (final item in items.where(
          (e) => e.storeId == storeId && e.productId == productId,
        )) {
          if (item.isAvailable) availabilityChanged = true;
          _productInStockByKey['$storeId:$productId'] = false;
          _repo.service.syncItemSnapshot(
            item.id,
            price: item.price,
            productName: item.productName,
            isAvailable: false,
            trackStock: item.trackStock,
            stockQuantity: 0,
            maxPerCustomer: item.maxPerCustomer,
          );
        }
      }

      for (final doc in snap.docs) {
        final product = Product.fromFirestore(storeId: storeId, doc: doc);
        _productInStockByKey['$storeId:${product.id}'] = product.isInStock;
        for (final item in items.where(
          (e) => e.storeId == storeId && e.productId == product.id,
        )) {
          final oldPrice = item.price;
          final wasAvailable = item.isAvailable;
          final store = _storesById[storeId];
          final sellable =
              product.isInStock && (store == null || _storeIsSellable(store));
          _repo.service.syncItemSnapshot(
            item.id,
            price: product.price,
            productName: product.name,
            imageUrl: product.imageUrl,
            imageThumbUrl: product.imageThumbUrl,
            isAvailable: sellable,
            trackStock: product.trackStock,
            stockQuantity: product.stockQuantity,
            maxPerCustomer: product.maxPerCustomer,
            discountPercent: product.effectiveDiscountPercent,
          );
          if ((oldPrice - product.price).abs() > 0.01) priceChanged = true;
          if (wasAvailable != sellable) availabilityChanged = true;
        }
      }
    } finally {
      _syncingRealtime = false;
    }

    _offline = false;
    if (priceChanged) {
      _notice = 'تم تحديث أسعار بعض المنتجات في سلتك';
    } else if (availabilityChanged) {
      _notice = 'تغيّر توفر بعض المنتجات في سلتك';
    }
    notifyListeners();
  }

  bool _storeIsSellable(Store store) => store.isSellable;

  void _applyStoreStatus() {
    _syncingRealtime = true;
    try {
      for (final item in items) {
        final store = _storesById[item.storeId];
        if (store == null) continue;
        final storeOk = _storeIsSellable(store);
        final productKey = '${item.storeId}:${item.productId}';
        final productInStock = _productInStockByKey[productKey];
        if (!storeOk) {
          if (item.isAvailable) {
            _repo.service.syncItemSnapshot(
              item.id,
              price: item.price,
              productName: item.productName,
              storeMinOrderAmount: store.minOrderAmount,
              isAvailable: false,
              trackStock: item.trackStock,
              stockQuantity: item.stockQuantity,
              maxPerCustomer: item.maxPerCustomer,
              discountPercent: item.discountPercent,
            );
            _notice = 'متجر «${store.name}» غير متاح حالياً';
          }
          continue;
        }

        // استعادة التوفر عند إعادة فتح المتجر من آخر معرفة للمنتج.
        final shouldBeAvailable = productInStock ?? item.isAvailable;
        final wasAvailable = item.isAvailable;
        final minOrderChanged =
            (store.minOrderAmount - item.storeMinOrderAmount).abs() > 0.01;
        if (minOrderChanged || wasAvailable != shouldBeAvailable) {
          _repo.service.syncItemSnapshot(
            item.id,
            price: item.price,
            productName: item.productName,
            storeMinOrderAmount: store.minOrderAmount,
            isAvailable: shouldBeAvailable,
            trackStock: item.trackStock,
            stockQuantity: item.stockQuantity,
            maxPerCustomer: item.maxPerCustomer,
            discountPercent: item.discountPercent,
          );
          if (!wasAvailable && shouldBeAvailable) {
            _notice = 'متجر «${store.name}» متاح مجدداً';
          }
        }
      }
    } finally {
      _syncingRealtime = false;
    }
  }

  Future<void> _loadSuggestions() async {
    final generation = ++_suggestionsGeneration;
    if (!suggestionsEnabled || isEmpty) {
      _suggestions = const [];
      _suggestionsLoading = false;
      notifyListeners();
      return;
    }
    _suggestionsLoading = true;
    notifyListeners();
    try {
      final cartProductIds = items.map((e) => e.productId).toSet();
      final storeIds = items.map((e) => e.storeId).toSet();
      final scored = <String, _ScoredProduct>{};

      for (final storeId in storeIds) {
        Store? store = _storesById[storeId];
        store ??= await _storeRepo.getStore(storeId);
        if (generation != _suggestionsGeneration) return;
        if (store != null) _storesById[storeId] = store;
        if (store != null && !_storeIsSellable(store)) continue;

        // One-shot read — لا تفتح listener دائم لكل تحميل مقترحات.
        final products = await _productRepo
            .fetchProductsOnce(storeId, activeOnly: true)
            .timeout(const Duration(seconds: 8), onTimeout: () => const []);
        if (generation != _suggestionsGeneration) return;

        for (final product in products) {
          if (!product.isInStock || cartProductIds.contains(product.id)) {
            continue;
          }
          var score = 10.0;
          if (product.bestSeller) score += 40;
          if (product.isFeatured) score += 25;
          score += product.ordersCount.clamp(0, 100) * 0.5;
          score += max(0, 20 - product.sortOrder).toDouble();
          scored[product.id] = _ScoredProduct(product: product, score: score);
        }
      }

      final freq = <String, int>{};
      for (final order in _orders.pastOrders) {
        if (!storeIds.contains(order.storeId)) continue;
        for (final line in order.lineItems) {
          if (cartProductIds.contains(line.productId)) continue;
          freq[line.productId] = (freq[line.productId] ?? 0) + line.quantity;
        }
      }
      for (final entry in freq.entries) {
        final current = scored[entry.key];
        if (current == null) continue;
        scored[entry.key] = _ScoredProduct(
          product: current.product,
          score: current.score + entry.value * 15,
        );
      }

      final ranked = scored.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      _suggestions =
          ranked.take(8).map((e) => e.product).toList(growable: false);
      _offline = false;
    } catch (error) {
      _suggestions = const [];
      if (_isNetworkError(error)) {
        _offline = true;
      }
    } finally {
      if (generation == _suggestionsGeneration) {
        _suggestionsLoading = false;
        notifyListeners();
      }
    }
  }

  bool _isNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('network') ||
        text.contains('unavailable') ||
        text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('offline');
  }

  Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
    for (var offset = 0; offset < values.length; offset += size) {
      yield values.sublist(offset, min(offset + size, values.length));
    }
  }

  @override
  void dispose() {
    _suggestionsDebounce?.cancel();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _repo.removeListener(_onCartChanged);
    _config.removeListener(_onConfigChanged);
    super.dispose();
  }
}

class _ScoredProduct {
  const _ScoredProduct({required this.product, required this.score});
  final Product product;
  final double score;
}
