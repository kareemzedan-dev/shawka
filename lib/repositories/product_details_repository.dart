import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/cart_repository.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/services/favorites_service.dart';

/// طبقة مستودع تفاصيل المنتج — واجهة مستقرة للـ Controller.
///
/// تغلّف [ProductRepository] + [StoreRepository] + [FavoritesService] +
/// [CartRepository] بحيث لا يلمس الـ UI الـ Services أو Firestore مباشرة.
class ProductDetailsRepository {
  ProductDetailsRepository({
    ProductRepository? products,
    StoreRepository? stores,
    FavoritesService? favorites,
    CartRepository? cart,
    FirebaseFirestore? firestore,
  })  : _productsOverride = products,
        _storesOverride = stores,
        _favoritesOverride = favorites,
        _cartOverride = cart,
        _firestoreOverride = firestore;

  // التبعيات مُهيّأة بكسل — لا نلمس Firebase حتى أول استخدام فعلي
  // (يُسهّل حقن بدائل الاختبار دون تهيئة Firebase).
  final ProductRepository? _productsOverride;
  final StoreRepository? _storesOverride;
  final FavoritesService? _favoritesOverride;
  final CartRepository? _cartOverride;
  final FirebaseFirestore? _firestoreOverride;

  ProductRepository? _productsCached;
  StoreRepository? _storesCached;
  CartRepository? _cartCached;
  FirebaseFirestore? _firestoreCached;

  ProductRepository get _products =>
      _productsOverride ?? (_productsCached ??= ProductRepository());
  StoreRepository get _stores =>
      _storesOverride ?? (_storesCached ??= StoreRepository());
  FavoritesService get _favorites =>
      _favoritesOverride ?? FavoritesService.instance;
  CartRepository get _cart =>
      _cartOverride ?? (_cartCached ??= CartRepository.instance);
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? (_firestoreCached ??= FirebaseFirestore.instance);

  FavoritesService get favorites => _favorites;

  CollectionReference<Map<String, dynamic>> _productsRef(String storeId) =>
      _firestore.collection(FirestorePaths.storeProducts(storeId));

  /// يراقب مستند المنتج لحظياً — يعيد null إذا حُذف.
  Stream<Product?> watchProduct({
    required String storeId,
    required String productId,
  }) {
    return _productsRef(storeId).doc(productId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Product.fromFirestore(storeId: storeId, doc: doc);
    });
  }

  /// يراقب مستند المتجر لحظياً — لحالة الفتح/الإغلاق والحد الأدنى.
  Stream<Store?> watchStore(String storeId) {
    return _firestore
        .collection(FirestorePaths.stores)
        .doc(storeId)
        .snapshots()
        .map((doc) => doc.exists ? Store.fromFirestore(doc) : null);
  }

  Future<Store?> getStore(String storeId) => _stores.getStore(storeId);

  /// مقترحات «أكمل وجبتك» — نفس المتجر، تفضيل نفس التصنيف، ثم الأكثر مبيعاً/طلباً/تقييماً.
  /// متوفر فقط، يستثني المنتج الحالي. قراءة لمرة واحدة (لا listener دائم).
  Future<List<Product>> fetchSuggestions({
    required String storeId,
    required String excludeProductId,
    String preferredCategory = '',
    int limit = 10,
  }) async {
    final products = await _products.fetchProductsOnce(
      storeId,
      activeOnly: true,
    );
    final scored = <_ScoredProduct>[];
    for (final product in products) {
      if (product.id == excludeProductId) continue;
      if (!product.isInStock) continue;
      var score = 10.0;
      if (preferredCategory.isNotEmpty && product.category == preferredCategory) {
        score += 50;
      }
      if (product.bestSeller) score += 40;
      if (product.isFeatured) score += 20;
      score += product.ordersCount.clamp(0, 200) * 0.5;
      score += min(product.rating, 5) * 4;
      score += max(0, 20 - product.sortOrder).toDouble();
      scored.add(_ScoredProduct(product: product, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.product).toList(growable: false);
  }

  bool isFavorite(String storeId, String productId) =>
      _favorites.isProductFavorite(storeId, productId);

  Future<void> toggleFavorite(String storeId, String productId) =>
      _favorites.toggleProduct(storeId, productId);

  void addFavoritesListener(VoidCallback listener) =>
      _favorites.addListener(listener);

  void removeFavoritesListener(VoidCallback listener) =>
      _favorites.removeListener(listener);

  /// يضيف المنتج للسلة عبر [CartRepository] — السعر النهائي يبقى خادمياً في Checkout.
  void addToCart({
    required Store store,
    required Product product,
    required int quantity,
    required double unitPrice,
    required String displayName,
    required String cartLineId,
    required List<String> addonIds,
    required String note,
  }) {
    _cart.addProduct(
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

  /// السطر الموجود في السلة لنفس المنتج (لاستعادة الكمية/الملاحظة/الإضافات).
  ({int quantity, String note, List<String> addonIds})? existingCartLine({
    required String storeId,
    required String productId,
  }) {
    for (final item in _cart.items) {
      if (item.storeId == storeId && item.productId == productId) {
        return (
          quantity: item.quantity,
          note: item.note,
          addonIds: List<String>.from(item.addonIds),
        );
      }
    }
    return null;
  }
}

class _ScoredProduct {
  const _ScoredProduct({required this.product, required this.score});
  final Product product;
  final double score;
}
