import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/services/favorites_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مستودع شاشة البحث — واجهة مستقرة للـ [SearchScreenController].
///
/// يغلّف الكتالوج + CMS + سجل البحث المرتبط بالمستخدم + المفضلة
/// دون أن يلمس الـ UI Firestore/Services مباشرة.
class SearchRepository {
  SearchRepository({
    CatalogService? catalog,
    CmsTextService? cms,
    FavoritesService? favorites,
    AuthService? auth,
    FirebaseAuth? firebaseAuth,
  })  : _catalogOverride = catalog,
        _cmsOverride = cms,
        _favoritesOverride = favorites,
        _auth = auth,
        _firebaseAuth = firebaseAuth;

  final CatalogService? _catalogOverride;
  CatalogService? _catalogCached;
  final CmsTextService? _cmsOverride;
  CmsTextService? _cmsCached;
  final FavoritesService? _favoritesOverride;
  FavoritesService? _favoritesCached;
  final AuthService? _auth;
  final FirebaseAuth? _firebaseAuth;

  /// كسول — لا يلمس Service Locator / Firebase حتى أول استخدام فعلي.
  CatalogService get _catalog =>
      _catalogOverride ?? (_catalogCached ??= CatalogService());

  CmsTextService get _cms =>
      _cmsOverride ?? (_cmsCached ??= CmsTextService.instance);

  FavoritesService get _favorites =>
      _favoritesOverride ?? (_favoritesCached ??= FavoritesService.instance);

  FirebaseAuth get _authFirebase => _firebaseAuth ?? FirebaseAuth.instance;

  static const _guestRecentKey = 'matlobgo_recent_searches_guest';
  static const _maxRecent = 8;
  static const _productStoreScanLimit = 10;

  final Map<String, List<Product>> _productCache = {};

  String? get _uid {
    final fromAuth = _auth?.currentUser?.uid;
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    try {
      return _authFirebase.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String get _recentPrefKey {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return _guestRecentKey;
    return 'matlobgo_recent_searches_$uid';
  }

  Stream<List<Store>> watchStores({required String governorate}) {
    return Stream.fromFuture(_activityTypeId()).asyncExpand(
      (activityTypeId) => _catalog.watchStores(
        governorate: governorate,
        activityTypeId: activityTypeId,
      ),
    );
  }

  Stream<List<StoreCategoryDef>> watchCategories(String governorate) {
    return Stream.fromFuture(_activityTypeId()).asyncExpand(
      (activityTypeId) => _catalog.watchCategories(
        governorate,
        activityTypeId: activityTypeId,
      ),
    );
  }

  Future<String> _activityTypeId() async {
    try {
      final auth = _auth ?? AuthService();
      final user = await auth.getCurrentAppUser();
      return user?.activityTypeId ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<List<Product>> productsForStore(Store store) async {
    final cached = _productCache[store.id];
    if (cached != null) return cached;
    try {
      final activityTypeId = await _activityTypeId();
      final list = await _catalog
          .watchProducts(store, activityTypeId: activityTypeId)
          .first;
      _productCache[store.id] = list;
      return list;
    } catch (_) {
      return const [];
    }
  }

  String searchHint() {
    try {
      return _cms.homeSearchHint(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String pageTitle() {
    try {
      return _cms.searchPageTitle(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String popularTitle() {
    try {
      return _cms.searchPopularTitle(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String recentTitle() {
    try {
      return _cms.searchRecentTitle(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String recentClearLabel() {
    try {
      return _cms.searchRecentClear(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String filterAllLabel() {
    try {
      return _cms.searchFilterAll(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String suggestedStoresTitle() {
    try {
      return _cms.searchSuggestedStoresTitle(fallback: '');
    } catch (_) {
      return '';
    }
  }

  String suggestedStoresSubtitle() {
    try {
      return _cms.searchSuggestedStoresSubtitle(fallback: '');
    } catch (_) {
      return '';
    }
  }

  List<String> suggestionLabels() {
    try {
      return _cms.searchSuggestions();
    } catch (_) {
      return const [];
    }
  }

  List<String> blacklist() {
    try {
      return _cms.searchBlacklist();
    } catch (_) {
      return const [];
    }
  }

  List<String> _trendingSafe() {
    try {
      return _cms.searchTrending();
    } catch (_) {
      return const [];
    }
  }

  bool isBlacklisted(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return blacklist().any((term) => normalized.contains(term.toLowerCase()));
  }

  Future<List<String>> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _recentPrefKey;
    var list = prefs.getStringList(key);
    // ترحيل السجل القديم (قبل ربطه بالمستخدم).
    if (list == null || list.isEmpty) {
      final legacy = prefs.getStringList('matlobgo_recent_searches');
      if (legacy != null && legacy.isNotEmpty) {
        await prefs.setStringList(key, legacy);
        list = legacy;
      }
    }
    return List<String>.from(list ?? const []);
  }

  Future<List<String>> saveRecentSearch(
    String query, {
    required List<String> current,
  }) async {
    final q = query.trim();
    if (q.length < 2 || isBlacklisted(q)) return current;
    final updated = [q, ...current.where((e) => e != q)].take(_maxRecent).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentPrefKey, updated);
    return updated;
  }

  Future<List<String>> removeRecentSearch(
    String query, {
    required List<String> current,
  }) async {
    final updated = current.where((e) => e != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentPrefKey, updated);
    return updated;
  }

  Future<List<String>> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentPrefKey);
    return const [];
  }

  /// الأكثر بحثاً — من لوحة التحكم فقط (`search_trending`)، بدون قيم مولّدة.
  List<PopularSearchTerm> popularSearches({
    required List<Store> stores,
  }) {
    final terms = <PopularSearchTerm>[];
    final seen = <String>{};

    for (final raw in _trendingSafe()) {
      final label = raw.trim();
      if (label.isEmpty) continue;
      final key = label.toLowerCase();
      if (seen.contains(key) || isBlacklisted(label)) continue;
      seen.add(key);
      terms.add(
        PopularSearchTerm(
          label: label,
          hot: label.contains('🔥') || label.contains('%') || label.contains('عرض'),
        ),
      );
    }

    return terms;
  }

  List<Store> suggestedStores(List<Store> stores, {int limit = 8}) {
    final open = stores.where((s) => s.isOpen).toList()
      ..sort((a, b) {
        final feat = (b.isFeaturedNow ? 1 : 0).compareTo(a.isFeaturedNow ? 1 : 0);
        if (feat != 0) return feat;
        final byOrders = b.totalOrders.compareTo(a.totalOrders);
        if (byOrders != 0) return byOrders;
        return b.rating.compareTo(a.rating);
      });
    return open.take(limit).toList();
  }

  /// بحث متزامن في المتاجر/التصنيفات + كلمات مفتاحية — مرتّب بالتطابق.
  List<SearchHit> rankStoreAndCategoryHits({
    required String query,
    required List<Store> stores,
    required List<StoreCategoryDef> categories,
    String? categoryId,
    SearchAdvancedFilters filters = const SearchAdvancedFilters(),
  }) {
    final q = query.trim().toLowerCase();
    if (isBlacklisted(q)) return const [];

    var list = List<Store>.from(stores);
    if (categoryId != null) {
      list = list
          .where(
            (s) => StoreCatalogUtils.matchesCategoryInSubtree(
              s,
              categoryId,
              categories,
            ),
          )
          .toList();
    }
    if (filters.openOnly) {
      list = list.where((s) => s.isOpen).toList();
    }
    if (filters.freeDeliveryOnly) {
      list = list.where((s) => s.deliveryFee <= 0).toList();
    }
    if (filters.offersOnly) {
      list = list
          .where(
            (s) =>
                (s.discountLabel ?? '').trim().isNotEmpty || s.isFeaturedNow,
          )
          .toList();
    }

    if (q.isEmpty) {
      final suggested = suggestedStores(list);
      return [
        for (final s in suggested)
          SearchHit.store(store: s, score: 1, matchedVia: SearchMatchVia.storeName),
      ];
    }

    final hits = <SearchHit>[];

    for (final cat in categories) {
      final name = cat.name.toLowerCase();
      if (!name.contains(q)) continue;
      final score = name.startsWith(q) ? 750 : 500;
      hits.add(SearchHit.category(category: cat, score: score));
    }

    for (final store in list) {
      final scored = _scoreStore(store, q);
      if (scored == null) continue;
      hits.add(
        SearchHit.store(
          store: store,
          score: scored.$1,
          matchedVia: scored.$2,
        ),
      );
    }

    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final aOpen = a.store?.isOpen == true ? 1 : 0;
      final bOpen = b.store?.isOpen == true ? 1 : 0;
      return bOpen.compareTo(aOpen);
    });
    return hits;
  }

  /// بحث منتجات محدود (مخزّن) — يُستدعى بعد debounce من الـ Controller.
  Future<List<SearchHit>> searchProducts({
    required String query,
    required List<Store> candidateStores,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2 || isBlacklisted(q)) return const [];

    final hits = <SearchHit>[];
    final stores = candidateStores.where((s) => s.isOpen).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    for (final store in stores.take(_productStoreScanLimit)) {
      final products = await productsForStore(store);
      for (final product in products) {
        if (!product.isInStock) continue;
        final name = product.name.toLowerCase();
        final desc = (product.description ?? '').toLowerCase();
        if (!name.contains(q) && !desc.contains(q)) continue;
        final score = name.startsWith(q)
            ? 720
            : name.contains(q)
                ? 580
                : 420;
        hits.add(
          SearchHit.product(store: store, product: product, score: score),
        );
        if (hits.length >= 24) {
          hits.sort((a, b) => b.score.compareTo(a.score));
          return hits;
        }
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits;
  }

  (int, SearchMatchVia)? _scoreStore(Store store, String q) {
    final name = store.name.toLowerCase();
    if (name == q) return (1000, SearchMatchVia.storeName);
    if (name.startsWith(q)) return (850, SearchMatchVia.storeName);
    if (name.contains(q)) return (700, SearchMatchVia.storeName);

    for (final tag in store.tags) {
      final t = tag.toLowerCase();
      if (t == q) return (650, SearchMatchVia.tags);
      if (t.startsWith(q) || t.contains(q)) return (520, SearchMatchVia.tags);
    }

    final cat = store.categoryLabel.toLowerCase();
    if (cat.contains(q)) return (400, SearchMatchVia.category);

    final area = store.area.toLowerCase();
    if (area.contains(q)) return (360, SearchMatchVia.keyword);

    final discount = (store.discountLabel ?? '').toLowerCase();
    if (discount.contains(q)) return (340, SearchMatchVia.keyword);

    return null;
  }

  bool isFavorite(String storeId) => _favorites.isFavorite(storeId);

  Future<void> toggleFavorite(String storeId) => _favorites.toggle(storeId);

  Listenable get favoritesListenable => _favorites;
}
