import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/cache/cache_policy.dart';
import 'package:matlobgo/core/cache/cached_firestore_stream.dart';
import 'package:matlobgo/core/cache/firestore_cache_store.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/data/mappers/product_mapper.dart';
import 'package:matlobgo/models/product.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _products(String storeId) =>
      _firestore.collection(FirestorePaths.storeProducts(storeId));

  Stream<List<Product>> watchProducts(
    String storeId, {
    bool activeOnly = false,
  }) {
    final source = _products(storeId).snapshots().map((snap) {
      var list = snap.docs
          .map((d) => Product.fromFirestore(storeId: storeId, doc: d))
          .toList();
      if (activeOnly) {
        list = list.where((p) => p.isAvailable).toList();
      }
      list.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.name.compareTo(b.name);
      });
      return list;
    });

    return cachedFirestoreStream<List<Product>>(
      cacheKey:
          '${CacheKeys.products(storeId)}:${activeOnly ? 'active' : 'all'}',
      policy: CachePolicy.catalog,
      source: source,
      decode: (json) => ProductMapper.fromCacheJson(json, storeId),
      encode: ProductMapper.toCacheJson,
    );
  }

  /// قراءة لمرة واحدة للمقترحات دون فتح listener دائم.
  Future<List<Product>> fetchProductsOnce(
    String storeId, {
    bool activeOnly = false,
  }) async {
    final snap = await _products(storeId).get();
    var list = snap.docs
        .map((d) => Product.fromFirestore(storeId: storeId, doc: d))
        .toList();
    if (activeOnly) {
      list = list.where((p) => p.isAvailable).toList();
    }
    list.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.name.compareTo(b.name);
    });
    return list;
  }

  Future<Product?> getProduct({
    required String storeId,
    required String productId,
  }) async {
    final doc = await _products(storeId).doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(storeId: storeId, doc: doc);
  }

  Future<String> createProduct(Product product) async {
    final ref = _products(product.storeId).doc();
    final data = _withoutServerAggregates(product.toFirestore())
      ..['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    await syncStoreProductActivities(product.storeId);
    return ref.id;
  }

  Future<void> updateProduct(Product product) async {
    await _products(product.storeId).doc(product.id).set(
      _withoutServerAggregates(product.toFirestore()),
      SetOptions(merge: true),
    );
    await syncStoreProductActivities(product.storeId);
  }

  Future<void> deleteProduct({
    required String storeId,
    required String productId,
  }) async {
    await _products(storeId).doc(productId).delete();
    await syncStoreProductActivities(storeId);
  }

  /// يحدّث اتحاد أنشطة المنتجات على المتجر حتى يظهر في الأنشطة الإضافية.
  Future<void> syncStoreProductActivities(String storeId) async {
    try {
      final snap = await _products(storeId).get();
      final ids = <String>{};
      for (final doc in snap.docs) {
        ids.addAll(ActivityScopeUtils.readIds(doc.data()['activityTypeIds']));
      }
      final sorted = ids.toList()..sort();
      await _firestore.collection(FirestorePaths.stores).doc(storeId).set({
        'productActivityTypeIds': sorted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      FirestoreCacheStore.instance.invalidate('stores:');
    } catch (_) {}
  }

  Future<void> batchUpdateSortOrder({
    required String storeId,
    required List<Product> ordered,
  }) async {
    if (ordered.isEmpty) return;
    final batch = _firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_products(storeId).doc(ordered[i].id), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> adjustStock({
    required String storeId,
    required String productId,
    required int delta,
  }) async {
    if (delta == 0) return;
    final ref = _products(storeId).doc(productId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final track = snap.data()?['trackStock'] as bool? ?? false;
      if (!track) return;
      final current = snap.data()?['stockQuantity'] as int? ?? 0;
      tx.update(ref, {
        'stockQuantity': (current + delta).clamp(0, 999999),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Map<String, dynamic> _withoutServerAggregates(
    Map<String, dynamic> data,
  ) => data
    ..remove('rating')
    ..remove('ratingSum')
    ..remove('reviewCount')
    ..remove('favoritesCount');
}
