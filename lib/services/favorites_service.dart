import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optimistic favorites backed by local preferences and the signed-in user's
/// Firestore subcollection.
class FavoritesService extends ChangeNotifier {
  FavoritesService._({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static final FavoritesService instance = FavoritesService._();

  static const _prefKey = 'matlobgo_favorite_store_ids';
  static const _productPrefKey = 'matlobgo_favorite_product_keys';

  final FirebaseFirestore _db;
  final Set<String> _ids = {};
  final Set<String> _productKeys = {};
  final Map<String, bool> _pending = {};
  final Map<String, String> _pendingStoreIds = {};
  final Map<String, String> _pendingProductKeys = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<String> get ids => List.unmodifiable(_ids);

  static String productKey(String storeId, String productId) =>
      '$storeId:$productId';

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_prefKey) ?? const []);
    _productKeys
      ..clear()
      ..addAll(prefs.getStringList(_productPrefKey) ?? const []);
    _initialized = true;
    notifyListeners();
  }

  /// Binds favorites to [uid]. Passing null keeps favorites local-only.
  ///
  /// The local cache is uploaded once on sign-in, then Firestore becomes the
  /// multi-device source of truth while optimistic writes remain immediate.
  Future<void> bindUser(String? uid) async {
    if (!_initialized) await init();
    if (_uid == uid) return;

    await _subscription?.cancel();
    _subscription = null;
    _pending.clear();
    _pendingStoreIds.clear();
    _pendingProductKeys.clear();
    _uid = uid?.trim().isEmpty == true ? null : uid;
    if (_uid == null) return;

    final localStores = Set<String>.from(_ids);
    final localProducts = Set<String>.from(_productKeys);
    for (final storeId in localStores) {
      final docId = _storeDocumentId(storeId);
      _pending[docId] = true;
      _pendingStoreIds[docId] = storeId;
    }
    for (final key in localProducts) {
      final parts = _splitProductKey(key);
      if (parts != null) {
        final docId = _productDocumentId(parts.$1, parts.$2);
        _pending[docId] = true;
        _pendingProductKeys[docId] = key;
      }
    }

    _subscription = _favoritesCollection(_uid!).snapshots().listen(
      _applyRemoteSnapshot,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[FavoritesService] listener failed: $error');
      },
    );

    try {
      final batch = _db.batch();
      for (final storeId in localStores) {
        batch.set(
          _favoritesCollection(_uid!).doc(_storeDocumentId(storeId)),
          _favoriteData(type: 'store', storeId: storeId),
          SetOptions(merge: true),
        );
      }
      for (final key in localProducts) {
        final parts = _splitProductKey(key);
        if (parts == null) continue;
        batch.set(
          _favoritesCollection(
            _uid!,
          ).doc(_productDocumentId(parts.$1, parts.$2)),
          _favoriteData(
            type: 'product',
            storeId: parts.$1,
            productId: parts.$2,
          ),
          SetOptions(merge: true),
        );
      }
      if (localStores.isNotEmpty || localProducts.isNotEmpty) {
        await batch.commit();
      }
    } catch (error) {
      for (final storeId in localStores) {
        _removePending(_storeDocumentId(storeId));
      }
      for (final key in localProducts) {
        final parts = _splitProductKey(key);
        if (parts != null) {
          _removePending(_productDocumentId(parts.$1, parts.$2));
        }
      }
      debugPrint('[FavoritesService] initial sync failed: $error');
    }
  }

  bool isFavorite(String storeId) => _ids.contains(storeId);

  bool isProductFavorite(String storeId, String productId) =>
      _productKeys.contains(productKey(storeId, productId));

  int get storeCount => _ids.length;

  int get productCount => _productKeys.length;

  int get totalCount => _ids.length + _productKeys.length;

  /// مفاتيح المنتجات المفضلة بصيغة `storeId:productId`.
  List<String> get productKeys => List.unmodifiable(_productKeys);

  /// أزواج (storeId, productId) للمنتجات المفضلة.
  List<(String storeId, String productId)> get productRefs {
    final out = <(String, String)>[];
    for (final key in _productKeys) {
      final parts = _splitProductKey(key);
      if (parts != null) out.add(parts);
    }
    return out;
  }

  Future<void> toggle(String storeId) async {
    final wasFavorite = _ids.contains(storeId);
    _setStoreFavorite(storeId, !wasFavorite);
    notifyListeners();
    final uid = _uid;
    final docId = _storeDocumentId(storeId);
    if (uid != null) {
      _pending[docId] = !wasFavorite;
      _pendingStoreIds[docId] = storeId;
    }
    try {
      await _persist();
      if (uid == null) return;
      final ref = _favoritesCollection(uid).doc(docId);
      if (wasFavorite) {
        await ref.delete();
      } else {
        await ref.set(_favoriteData(type: 'store', storeId: storeId));
      }
    } catch (error) {
      _removePending(docId);
      _setStoreFavorite(storeId, wasFavorite);
      notifyListeners();
      await _persist();
      rethrow;
    }
  }

  Future<void> toggleProduct(String storeId, String productId) async {
    final key = productKey(storeId, productId);
    final wasFavorite = _productKeys.contains(key);
    _setProductFavorite(key, !wasFavorite);
    notifyListeners();
    final uid = _uid;
    final docId = _productDocumentId(storeId, productId);
    if (uid != null) {
      _pending[docId] = !wasFavorite;
      _pendingProductKeys[docId] = key;
    }
    try {
      await _persist();
      if (uid == null) return;
      final ref = _favoritesCollection(uid).doc(docId);
      if (wasFavorite) {
        await ref.delete();
      } else {
        await ref.set(
          _favoriteData(
            type: 'product',
            storeId: storeId,
            productId: productId,
          ),
        );
      }
    } catch (error) {
      _removePending(docId);
      _setProductFavorite(key, wasFavorite);
      notifyListeners();
      await _persist();
      rethrow;
    }
  }

  Future<void> remove(String storeId) async {
    if (!_ids.remove(storeId)) return;
    notifyListeners();
    final uid = _uid;
    final docId = _storeDocumentId(storeId);
    if (uid != null) {
      _pending[docId] = false;
      _pendingStoreIds[docId] = storeId;
    }
    try {
      await _persist();
      if (uid == null) return;
      await _favoritesCollection(uid).doc(docId).delete();
    } catch (error) {
      _removePending(docId);
      _ids.add(storeId);
      notifyListeners();
      await _persist();
      rethrow;
    }
  }

  Future<void> removeProduct(String storeId, String productId) async {
    final key = productKey(storeId, productId);
    if (!_productKeys.remove(key)) return;
    notifyListeners();
    final uid = _uid;
    final docId = _productDocumentId(storeId, productId);
    if (uid != null) {
      _pending[docId] = false;
      _pendingProductKeys[docId] = key;
    }
    try {
      await _persist();
      if (uid == null) return;
      await _favoritesCollection(uid).doc(docId).delete();
    } catch (error) {
      _removePending(docId);
      _productKeys.add(key);
      notifyListeners();
      await _persist();
      rethrow;
    }
  }

  CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) =>
      _db.collection(FirestorePaths.userFavorites(uid));

  Map<String, dynamic> _favoriteData({
    required String type,
    required String storeId,
    String productId = '',
  }) => {
    'type': type,
    'storeId': storeId,
    'productId': productId,
    'createdAt': FieldValue.serverTimestamp(),
  };

  void _applyRemoteSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final remoteStores = <String>{};
    final remoteProducts = <String>{};
    final remoteDocumentIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final storeId = data['storeId'];
      final productId = data['productId'];
      if (storeId is! String || storeId.isEmpty) continue;
      remoteDocumentIds.add(doc.id);
      if (type == 'store') {
        remoteStores.add(storeId);
      } else if (type == 'product' &&
          productId is String &&
          productId.isNotEmpty) {
        remoteProducts.add(productKey(storeId, productId));
      }
    }

    for (final entry in Map<String, bool>.from(_pending).entries) {
      if (remoteDocumentIds.contains(entry.key) == entry.value) {
        _removePending(entry.key);
      }
    }

    _ids
      ..clear()
      ..addAll(remoteStores);
    _productKeys
      ..clear()
      ..addAll(remoteProducts);
    for (final entry in _pending.entries) {
      _applyPending(entry.key, entry.value);
    }
    notifyListeners();
    unawaited(_persist());
  }

  void _applyPending(String documentId, bool value) {
    final storeId = _pendingStoreIds[documentId];
    if (storeId != null) {
      _setStoreFavorite(storeId, value);
      return;
    }
    final key = _pendingProductKeys[documentId];
    if (key != null) _setProductFavorite(key, value);
  }

  void _removePending(String documentId) {
    _pending.remove(documentId);
    _pendingStoreIds.remove(documentId);
    _pendingProductKeys.remove(documentId);
  }

  void _setStoreFavorite(String storeId, bool value) {
    if (value) {
      _ids.add(storeId);
    } else {
      _ids.remove(storeId);
    }
  }

  void _setProductFavorite(String key, bool value) {
    if (value) {
      _productKeys.add(key);
    } else {
      _productKeys.remove(key);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _ids.toList());
    await prefs.setStringList(_productPrefKey, _productKeys.toList());
  }

  static String _storeDocumentId(String storeId) => 'store_$storeId';

  static String _productDocumentId(String storeId, String productId) =>
      'product_${storeId}_$productId';

  static (String, String)? _splitProductKey(String key) {
    final separator = key.indexOf(':');
    if (separator <= 0 || separator == key.length - 1) return null;
    return (key.substring(0, separator), key.substring(separator + 1));
  }
}
