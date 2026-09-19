import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/product_addon.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/cart_repository.dart';
import 'package:matlobgo/repositories/product_details_repository.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/cart_service.dart';

/// حالة زر «إضافة إلى السلة».
enum ProductCtaState { normal, disabled, loading, success, error }

/// حالة شاشة تفاصيل المنتج — UI يعتمد عليها فقط (لا Firestore/Services مباشرة).
///
/// مرجع: [CartController] / [CheckoutController].
class ProductDetailsController extends ChangeNotifier {
  ProductDetailsController({
    required Store initialStore,
    required Product initialProduct,
    required List<Product> relatedProducts,
    required CartService cartService,
    ProductDetailsRepository? repository,
  })  : _store = initialStore,
        _product = initialProduct,
        // عند غياب المستودع المحقون نبني افتراضياً يستخدم نفس `cartService`
        // المُمرَّر (لتفادي تجاهله والرجوع الصامت إلى `CartRepository.instance`).
        _repo = repository ??
            ProductDetailsRepository(
              cart: CartRepository(service: cartService),
            ) {
    _lastKnownPrice = initialProduct.price;
    // بذور المقترحات من القائمة المُمرَّرة حتى يكتمل الجلب اللحظي.
    _suggestions = relatedProducts
        .where((p) => p.id != initialProduct.id && p.isInStock)
        .toList(growable: false);

    _restoreFromCart();
    _clampQuantityToStock();

    _repo.addFavoritesListener(_onFavoritesChanged);
    _bindRealtime();
    unawaited(_loadSuggestions());
  }

  final ProductDetailsRepository _repo;

  Store _store;
  Product _product;

  int _quantity = 1;
  String _note = '';
  final Set<String> _selectedAddonIds = {};

  List<Product> _suggestions = const [];
  bool _suggestionsLoading = false;

  ProductCtaState _ctaState = ProductCtaState.normal;
  String? _notice;
  bool _offline = false;
  bool _productMissing = false;
  double _lastKnownPrice = 0;

  StreamSubscription<Product?>? _productSub;
  StreamSubscription<Store?>? _storeSub;
  Timer? _ctaResetTimer;

  // ── Getters عامة للـ UI ──
  Store get store => _store;
  Product get product => _product;
  int get quantity => _quantity;
  String get note => _note;
  int get noteLength => _note.length;
  int get noteMaxLength => 200;
  Set<String> get selectedAddonIds => Set.unmodifiable(_selectedAddonIds);

  List<Product> get suggestions => _suggestions;
  bool get suggestionsLoading => _suggestionsLoading;

  ProductCtaState get ctaState => _ctaState;
  String? get notice => _notice;
  bool get offline => _offline;
  bool get productMissing => _productMissing;

  bool get isFavorite => _repo.isFavorite(_store.id, _product.id);

  /// الإضافات المتاحة فقط.
  List<ProductAddon> get availableAddons =>
      _product.addons.where((a) => a.isAvailable).toList(growable: false);

  double get addonsTotal => availableAddons
      .where((a) => _selectedAddonIds.contains(a.id))
      .fold(0.0, (sum, a) => sum + a.price);

  double get unitPrice => _product.price + addonsTotal;

  double get lineTotal => unitPrice * _quantity;

  bool get storeIsSellable => _store.isSellable;

  bool get isPurchasable =>
      !_productMissing && _product.isInStock && storeIsSellable;

  /// الحد الأقصى للكمية — مخزون + حد العميل من لوحة التحكم.
  int get maxQuantity {
    final max = _product.maxOrderQuantity;
    return max > 0 ? max : 1;
  }

  bool get canIncrement => _quantity < maxQuantity;
  bool get canDecrement => _quantity > 1;

  /// سبب تعطيل الشراء (لعرضه في الشريط السفلي/الحالة).
  String? get unavailableReason {
    if (_productMissing) return 'لم يعد هذا المنتج متاحاً';
    if (!_product.isAvailable) return 'المنتج غير متاح حالياً';
    if (_product.trackStock && _product.stockQuantity <= 0) {
      return 'نفد المخزون';
    }
    if (!storeIsSellable) return 'المتجر مغلق حالياً';
    return null;
  }

  // ── إجراءات المستخدم ──
  void increment() {
    if (!canIncrement) {
      _setNotice('وصلت للحد الأقصى المتاح من المخزون');
      return;
    }
    _quantity++;
    _resetTransientCta();
    _trackQuantity();
    notifyListeners();
  }

  void decrement() {
    if (!canDecrement) return;
    _quantity--;
    _resetTransientCta();
    _trackQuantity();
    notifyListeners();
  }

  void setNote(String value) {
    var next = value;
    if (next.length > noteMaxLength) {
      next = next.substring(0, noteMaxLength);
    }
    if (next == _note) return;
    _note = next;
    _resetTransientCta();
    notifyListeners();
  }

  void toggleAddon(String addonId) {
    if (_selectedAddonIds.contains(addonId)) {
      _selectedAddonIds.remove(addonId);
    } else {
      _selectedAddonIds.add(addonId);
    }
    _resetTransientCta();
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final wasFavorite = isFavorite;
    _track(
      AnalyticsEventType.favoriteToggle,
      label: wasFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
      metadata: {'favorite': !wasFavorite},
    );
    // FavoritesService متفائل بالفعل ويُشعر المستمعين.
    await _repo.toggleFavorite(_store.id, _product.id);
  }

  /// يشارك المنتج (نسخ للحافظة — لا يوجد share_plus في pubspec) ويعيد النص المشارَك.
  Future<String> share() async {
    final buffer = StringBuffer()
      ..writeln(_product.name)
      ..writeln('${_product.price.toStringAsFixed(0)} ج.م · ${_store.name}');
    final text = buffer.toString().trim();
    _track(
      AnalyticsEventType.productShare,
      label: 'مشاركة ${_product.name}',
    );
    await Clipboard.setData(ClipboardData(text: text));
    return text;
  }

  Future<void> addToCart() async {
    if (_ctaState == ProductCtaState.loading) return;
    final blockReason = unavailableReason;
    if (blockReason != null) {
      _setNotice(blockReason);
      _ctaState = ProductCtaState.error;
      _scheduleCtaReset();
      notifyListeners();
      return;
    }

    _ctaState = ProductCtaState.loading;
    notifyListeners();
    try {
      _repo.addToCart(
        store: _store,
        product: _product,
        quantity: _quantity,
        unitPrice: unitPrice,
        displayName: _displayName(),
        cartLineId: _cartLineId(),
        addonIds: _selectedAddonIds.toList(growable: false),
        note: _note.trim(),
      );
      _track(
        AnalyticsEventType.addToCart,
        label: 'إضافة ${_product.name}',
        metadata: {
          'quantity': _quantity,
          'addons': _selectedAddonIds.length,
          'unitPrice': unitPrice,
        },
      );
      _ctaState = ProductCtaState.success;
      notifyListeners();
    } catch (error) {
      _ctaState = ProductCtaState.error;
      if (_isNetworkError(error)) _offline = true;
      _setNotice('تعذّرت الإضافة إلى السلة — حاول مرة أخرى');
      _scheduleCtaReset();
      notifyListeners();
    }
  }

  /// إضافة منتج مقترح (نفس المتجر) للسلة مباشرة بكمية 1.
  void addSuggestionToCart(Product suggestion) {
    if (!storeIsSellable || !suggestion.isInStock) {
      _setNotice('تعذّرت الإضافة — المنتج أو المتجر غير متاح');
      notifyListeners();
      return;
    }
    _repo.addToCart(
      store: _store,
      product: suggestion,
      quantity: 1,
      unitPrice: suggestion.price,
      displayName: suggestion.name,
      cartLineId: '${_store.id}_${suggestion.id}',
      addonIds: const [],
      note: '',
    );
    _track(
      AnalyticsEventType.addSuggestionToCart,
      label: 'إضافة من المقترحات',
      productId: suggestion.id,
      productName: suggestion.name,
    );
    _setNotice('تمت إضافة ${suggestion.name} إلى السلة');
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }

  void acknowledgeCtaSuccess() {
    if (_ctaState == ProductCtaState.success) {
      _ctaState = ProductCtaState.normal;
      notifyListeners();
    }
  }

  // ── Realtime binding ──
  void _bindRealtime() {
    _productSub = _repo
        .watchProduct(storeId: _store.id, productId: _product.id)
        .listen(_onProductSnapshot, onError: _onStreamError);
    _storeSub = _repo
        .watchStore(_store.id)
        .listen(_onStoreSnapshot, onError: _onStreamError);
  }

  void _onProductSnapshot(Product? product) {
    _offline = false;
    if (product == null) {
      if (!_productMissing) {
        _productMissing = true;
        _setNotice('لم يعد هذا المنتج متاحاً');
      }
      notifyListeners();
      return;
    }
    _productMissing = false;
    final wasAvailable = _product.isInStock;
    final priceChanged = (product.price - _lastKnownPrice).abs() > 0.01;

    _product = product;
    _clampQuantityToStock();

    if (priceChanged) {
      _lastKnownPrice = product.price;
      _setNotice('تم تحديث سعر المنتج');
    } else if (wasAvailable && !product.isInStock) {
      _setNotice(
        product.trackStock && product.stockQuantity <= 0
            ? 'نفد المخزون'
            : 'لم يعد المنتج متاحاً حالياً',
      );
    }
    notifyListeners();
  }

  void _onStoreSnapshot(Store? store) {
    _offline = false;
    if (store == null) {
      notifyListeners();
      return;
    }
    final wasSellable = storeIsSellable;
    _store = store;
    final nowSellable = storeIsSellable;
    if (wasSellable && !nowSellable) {
      _setNotice('المتجر «${store.name}» مغلق حالياً');
    }
    notifyListeners();
  }

  void _onStreamError(Object error, StackTrace _) {
    if (_isNetworkError(error)) {
      _offline = true;
      notifyListeners();
    }
  }

  void _onFavoritesChanged() => notifyListeners();

  // ── Suggestions ──
  Future<void> _loadSuggestions() async {
    _suggestionsLoading = _suggestions.isEmpty;
    if (_suggestionsLoading) notifyListeners();
    try {
      final fetched = await _repo
          .fetchSuggestions(
            storeId: _store.id,
            excludeProductId: _product.id,
            preferredCategory: _product.category,
          )
          .timeout(const Duration(seconds: 8), onTimeout: () => const []);
      if (fetched.isNotEmpty) {
        _suggestions = fetched;
        _offline = false;
      }
    } catch (error) {
      if (_isNetworkError(error) && _suggestions.isEmpty) _offline = true;
    } finally {
      _suggestionsLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ──
  void _restoreFromCart() {
    final existing = _repo.existingCartLine(
      storeId: _store.id,
      productId: _product.id,
    );
    if (existing == null) return;
    _quantity = existing.quantity < 1 ? 1 : existing.quantity;
    _note = existing.note.length > noteMaxLength
        ? existing.note.substring(0, noteMaxLength)
        : existing.note;
    final availableIds = availableAddons.map((a) => a.id).toSet();
    _selectedAddonIds
      ..clear()
      ..addAll(existing.addonIds.where(availableIds.contains));
  }

  void _clampQuantityToStock() {
    final max = maxQuantity;
    if (_quantity > max) _quantity = max;
    if (_quantity < 1) _quantity = 1;
  }

  String _cartLineId() {
    final addonsKey = _selectedAddonIds.toList()..sort();
    final note = _note.trim();
    return '${_store.id}_${_product.id}_${addonsKey.join("-")}_${note.hashCode}';
  }

  String _displayName() {
    final labels = availableAddons
        .where((a) => _selectedAddonIds.contains(a.id))
        .map((a) => a.name)
        .toList();
    var name = _product.name;
    if (labels.isNotEmpty) name = '$name (${labels.join('، ')})';
    final note = _note.trim();
    if (note.isNotEmpty) name = '$name • $note';
    return name;
  }

  void _setNotice(String message) => _notice = message;

  void _resetTransientCta() {
    _ctaResetTimer?.cancel();
    if (_ctaState == ProductCtaState.success ||
        _ctaState == ProductCtaState.error) {
      _ctaState = ProductCtaState.normal;
    }
  }

  void _scheduleCtaReset() {
    _ctaResetTimer?.cancel();
    _ctaResetTimer = Timer(const Duration(seconds: 2), () {
      if (_ctaState == ProductCtaState.error) {
        _ctaState = ProductCtaState.normal;
        notifyListeners();
      }
    });
  }

  void _trackQuantity() {
    _track(
      AnalyticsEventType.productQuantityChange,
      label: 'تعديل كمية ${_product.name}',
      metadata: {'quantity': _quantity},
    );
  }

  /// التتبّع طرفي (fire-and-forget) — لا يجب أن يُفشل أي تدفّق للمستخدم.
  void _track(
    AnalyticsEventType type, {
    required String label,
    String? productId,
    String? productName,
    Map<String, dynamic>? metadata,
  }) {
    try {
      unawaited(
        AnalyticsService.instance.track(
          type: type,
          screen: 'product_detail',
          label: label,
          storeId: _store.id,
          storeName: _store.name,
          productId: productId ?? _product.id,
          productName: productName ?? _product.name,
          metadata: metadata,
        ),
      );
    } catch (_) {
      // تجاهل — التتبّع لا يجب أن يؤثّر على المنطق.
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

  @override
  void dispose() {
    _ctaResetTimer?.cancel();
    unawaited(_productSub?.cancel());
    unawaited(_storeSub?.cancel());
    _repo.removeFavoritesListener(_onFavoritesChanged);
    super.dispose();
  }
}
