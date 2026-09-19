import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/cache/cache_policy.dart';
import 'package:matlobgo/core/cache/firestore_cache_store.dart';
import 'package:matlobgo/core/cache/cached_firestore_stream.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/data/mappers/store_mapper.dart';
import 'package:matlobgo/models/store.dart';

class StoreRepository {
  StoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.stores);

  /// للعميل: متاجر نشطة في محافظة.
  /// يجب فلترة isActive في الاستعلام ليتوافق مع firestore.rules (وإلا PERMISSION_DENIED).
  Stream<List<Store>> watchActiveStores({
    required String governorate,
    String? categoryId,
  }) {
    final key = CacheKeys.stores(governorate, categoryId);
    final source = _collection
        .where('governorate', isEqualTo: governorate)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          var stores = snap.docs.map(Store.fromFirestore).toList();
          return StoreCatalogUtils.filterStores(stores, categoryId: categoryId);
        });

    return cachedFirestoreStream<List<Store>>(
      cacheKey: key,
      policy: CachePolicy.catalog,
      source: source,
      decode: StoreMapper.fromCacheJson,
      encode: StoreMapper.toCacheJson,
    );
  }

  /// لوحة التحكم: كل متاجر المحافظة.
  Stream<List<Store>> watchStoresByGovernorate({
    required String governorate,
    String? categoryId,
  }) {
    return _collection
        .where('governorate', isEqualTo: governorate)
        .snapshots()
        .map((snap) {
          var stores = snap.docs.map(Store.fromFirestore).toList();
          stores = StoreCatalogUtils.filterStores(
            stores,
            categoryId: categoryId,
          );
          stores.sort((a, b) => a.name.compareTo(b.name));
          return stores;
        });
  }

  Future<Store?> getStore(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Store.fromFirestore(doc);
  }

  Future<String> createStore(Store store) async {
    final ref = _collection.doc();
    final data = _withoutServerAggregates(store.toFirestore())
      ..['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    _invalidateStoreCache(store.governorate);
    return ref.id;
  }

  Future<void> updateStore(Store store) {
    _invalidateStoreCache(store.governorate);
    final data = _withoutServerAggregates(store.toFirestore());
    // عند مسح الموقع من اللوحة يجب حذف الحقول من Firestore (merge لا يكفي).
    if (!store.hasLocation) {
      data['latitude'] = FieldValue.delete();
      data['longitude'] = FieldValue.delete();
    }
    return _collection.doc(store.id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteStore(String id) async {
    await _collection.doc(id).delete();
    FirestoreCacheStore.instance.invalidate('stores:');
  }

  void _invalidateStoreCache(String governorate) {
    FirestoreCacheStore.instance.invalidate('stores:$governorate');
  }

  static Map<String, dynamic> _withoutServerAggregates(
    Map<String, dynamic> data,
  ) => data
    ..remove('rating')
    ..remove('ratingSum')
    ..remove('reviewCount')
    ..remove('totalFavorites');
}
