import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/repositories/search_repository.dart';
import 'package:matlobgo/screens/home/product/product_details_navigation.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';
import 'package:matlobgo/screens/home/store_detail_screen.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/cart_service.dart';

/// حالة شاشة البحث — الـ UI يعتمد عليها فقط.
///
/// Reference Implementation v5: UI رفيع → [SearchScreenController] → [SearchRepository].
class SearchScreenController extends ChangeNotifier {
  SearchScreenController({
    required this.governorate,
    required this.cartService,
    SearchRepository? repository,
    this.onVoiceSearch,
  }) : _repo = repository ?? SearchRepository() {
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textController.addListener(_onTextEditing);
    _favoritesListenable = _repo.favoritesListenable;
    _favoritesListenable.addListener(_onFavoritesChanged);
    unawaited(_bootstrap());
  }

  final String governorate;
  final CartService cartService;
  final SearchRepository _repo;
  final VoidCallback? onVoiceSearch;

  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final Listenable _favoritesListenable;

  StreamSubscription<List<Store>>? _storesSub;
  StreamSubscription<List<StoreCategoryDef>>? _categoriesSub;
  Timer? _debounce;
  Timer? _loadingTimer;
  int _productSearchGen = 0;

  List<Store> _stores = const [];
  List<StoreCategoryDef> _allCategories = const [];
  List<String> _recent = const [];
  List<SearchHit> _storeHits = const [];
  List<SearchHit> _productHits = const [];
  String? _categoryId;
  SearchAdvancedFilters _advanced = const SearchAdvancedFilters();
  String _debouncedQuery = '';
  bool _loading = true;
  bool _offline = false;
  bool _streamError = false;
  bool _openTracked = false;
  String? _notice;
  int _visibleCount = SearchTokens.resultsPageSize;

  TextEditingController get textController => _textController;
  FocusNode get focusNode => _focusNode;

  String get query => _textController.text;
  String get debouncedQuery => _debouncedQuery;
  bool get hasQuery => _debouncedQuery.trim().isNotEmpty;

  String? get categoryId => _categoryId;
  SearchAdvancedFilters get advancedFilters => _advanced;
  /// جذور فقط — تظهر في دوّارة/فلاتر الصفحة الرئيسية للبحث.
  List<StoreCategoryDef> get categories =>
      StoreCatalogUtils.roots(_allCategories);
  List<StoreCategoryDef> get allCategories => _allCategories;
  List<String> get recentSearches => _recent;
  List<Store> get allStores => _stores;

  List<PopularSearchTerm> get popularTerms =>
      _repo.popularSearches(stores: _stores);

  List<String> get suggestionLabels => _repo.suggestionLabels();

  String get searchHint => _repo.searchHint();
  String get pageTitle => _repo.pageTitle();
  String get popularTitle => _repo.popularTitle();
  String get recentTitle => _repo.recentTitle();
  String get recentClearLabel => _repo.recentClearLabel();
  String get filterAllLabel => _repo.filterAllLabel();
  String get suggestedStoresTitle => _repo.suggestedStoresTitle();
  String get suggestedStoresSubtitle => _repo.suggestedStoresSubtitle();

  List<Store> get suggestedStores => _repo.suggestedStores(_filteredStores());

  List<SearchHit> get rankedHits {
    final merged = <SearchHit>[..._storeHits, ..._productHits]
      ..sort((a, b) => b.score.compareTo(a.score));
    return merged;
  }

  List<SearchHit> get visibleHits =>
      rankedHits.take(_visibleCount).toList(growable: false);

  bool get canLoadMore => rankedHits.length > _visibleCount;

  bool get loading => _loading;
  bool get offline => _offline;
  bool get hasError => _streamError;
  String? get notice => _notice;

  SearchUiPhase get phase {
    if (_offline && _stores.isEmpty) return SearchUiPhase.offline;
    if (_streamError && _stores.isEmpty) return SearchUiPhase.error;
    if (_loading && _stores.isEmpty) return SearchUiPhase.loading;
    if (hasQuery && rankedHits.isEmpty) return SearchUiPhase.empty;
    if (!hasQuery && _stores.isEmpty && !_loading) return SearchUiPhase.empty;
    if (!hasQuery) return SearchUiPhase.initial;
    return SearchUiPhase.success;
  }

  bool isFavorite(String storeId) => _repo.isFavorite(storeId);

  Future<void> _bootstrap() async {
    _loadingTimer = Timer(const Duration(milliseconds: 700), () {
      if (_loading) {
        _loading = false;
        notifyListeners();
      }
    });

    _recent = await _repo.loadRecentSearches();
    notifyListeners();

    _categoriesSub = _repo.watchCategories(governorate).listen(
      (cats) {
        _allCategories = cats;
        _offline = false;
        _streamError = false;
        _recompute();
      },
      onError: (_) {
        _streamError = true;
        _offline = true;
        _loading = false;
        notifyListeners();
      },
    );

    _storesSub = _repo.watchStores(governorate: governorate).listen(
      (stores) {
        _stores = stores;
        _offline = false;
        _streamError = false;
        _loading = false;
        _loadingTimer?.cancel();
        _recompute();
        _trackOpenOnce();
      },
      onError: (_) {
        _streamError = true;
        _offline = true;
        _loading = false;
        notifyListeners();
      },
    );
  }

  void _onTextEditing() => notifyListeners();

  void onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(SearchTokens.debounce, () {
      final next = _textController.text.trim();
      if (next == _debouncedQuery) return;
      _debouncedQuery = next;
      _visibleCount = SearchTokens.resultsPageSize;
      _recompute();
      unawaited(_runProductSearch());
      if (next.length >= 2) {
        _track(
          AnalyticsEventType.searchQuery,
          label: 'بحث: $next',
          metadata: {'query': next},
        );
      }
    });
  }

  void clearQuery() {
    _textController.clear();
    _debouncedQuery = '';
    _productHits = const [];
    _visibleCount = SearchTokens.resultsPageSize;
    _recompute();
  }

  void selectCategory(String? id) {
    if (_categoryId == id) return;
    _categoryId = id;
    _visibleCount = SearchTokens.resultsPageSize;
    _recompute();
    unawaited(_runProductSearch());
    _track(
      AnalyticsEventType.searchFilter,
      label: id == null ? 'فلتر الكل' : 'فلتر $id',
      metadata: {'categoryId': id ?? ''},
    );
  }

  void applySuggestion(String label) {
    _textController
      ..text = label
      ..selection = TextSelection.collapsed(offset: label.length);
    _debouncedQuery = label.trim();
    _visibleCount = SearchTokens.resultsPageSize;
    unawaited(_persistRecent(label));
    _recompute();
    unawaited(_runProductSearch());
    _track(
      AnalyticsEventType.searchSuggestion,
      label: 'اقتراح: $label',
      metadata: {'query': label},
    );
  }

  void updateAdvancedFilters(SearchAdvancedFilters filters) {
    _advanced = filters;
    _visibleCount = SearchTokens.resultsPageSize;
    _recompute();
    unawaited(_runProductSearch());
  }

  void loadMore() {
    if (!canLoadMore) return;
    _visibleCount += SearchTokens.resultsPageSize;
    notifyListeners();
  }

  Future<void> removeRecent(String query) async {
    _recent = await _repo.removeRecentSearch(query, current: _recent);
    notifyListeners();
  }

  Future<void> clearRecent() async {
    _recent = await _repo.clearRecentSearches();
    notifyListeners();
    _track(
      AnalyticsEventType.searchClearRecent,
      label: 'مسح سجل البحث',
    );
  }

  Future<void> toggleFavorite(String storeId) async {
    final store = _stores.where((s) => s.id == storeId).firstOrNull;
    await _repo.toggleFavorite(storeId);
    _track(
      AnalyticsEventType.favoriteToggle,
      label: 'مفضلة من البحث',
      storeId: storeId,
      storeName: store?.name ?? '',
    );
  }

  void requestVoiceSearch() {
    if (onVoiceSearch != null) {
      onVoiceSearch!();
      return;
    }
    _notice = 'البحث الصوتي قريباً';
    notifyListeners();
  }

  void clearNotice() => _notice = null;

  Future<void> openStore(BuildContext context, Store store) async {
    if (hasQuery) await _persistRecent(_debouncedQuery);
    _track(
      AnalyticsEventType.storeView,
      label: 'فتح متجر من البحث',
      storeId: store.id,
      storeName: store.name,
    );
    if (!context.mounted) return;
    openStoreDetail(context, store: store, cartService: cartService);
  }

  Future<void> openProduct(
    BuildContext context, {
    required Store store,
    required Product product,
  }) async {
    if (hasQuery) await _persistRecent(_debouncedQuery);
    final related = await _repo.productsForStore(store);
    if (!context.mounted) return;
    openProductDetail(
      context,
      store: store,
      product: product,
      relatedProducts: related,
      cartService: cartService,
    );
  }

  Future<void> refresh() async {
    _loading = true;
    _streamError = false;
    _offline = false;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _loading = false;
    _recompute();
  }

  List<Store> _filteredStores() {
    final id = _categoryId;
    if (id == null) return _stores;
    return _stores
        .where(
          (s) => StoreCatalogUtils.matchesCategoryInSubtree(
            s,
            id,
            _allCategories,
          ),
        )
        .toList();
  }

  void _recompute() {
    _storeHits = _repo.rankStoreAndCategoryHits(
      query: _debouncedQuery,
      stores: _stores,
      categories: _allCategories,
      categoryId: _categoryId,
      filters: _advanced,
    );
    notifyListeners();
  }

  Future<void> _runProductSearch() async {
    final q = _debouncedQuery.trim();
    final gen = ++_productSearchGen;
    if (q.length < 2) {
      _productHits = const [];
      notifyListeners();
      return;
    }

    final candidates = _storeHits
        .where((h) => h.store != null)
        .map((h) => h.store!)
        .toList();
    final pool = candidates.isNotEmpty
        ? candidates
        : _filteredStores().where((s) => s.isOpen).toList();

    final hits = await _repo.searchProducts(query: q, candidateStores: pool);
    if (gen != _productSearchGen) return;
    _productHits = hits;
    notifyListeners();
  }

  Future<void> _persistRecent(String query) async {
    _recent = await _repo.saveRecentSearch(query, current: _recent);
    notifyListeners();
  }

  void _onFavoritesChanged() => notifyListeners();

  void _trackOpenOnce() {
    if (_openTracked) return;
    _openTracked = true;
    unawaited(
      AnalyticsService.instance.screenView(screen: 'search', label: 'البحث'),
    );
    _track(
      AnalyticsEventType.searchOpen,
      label: 'فتح البحث',
    );
  }

  void _track(
    AnalyticsEventType type, {
    required String label,
    String storeId = '',
    String storeName = '',
    Map<String, dynamic>? metadata,
  }) {
    unawaited(
      AnalyticsService.instance.track(
        type: type,
        screen: 'search',
        label: label,
        storeId: storeId,
        storeName: storeName,
        metadata: metadata,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _loadingTimer?.cancel();
    _storesSub?.cancel();
    _categoriesSub?.cancel();
    _favoritesListenable.removeListener(_onFavoritesChanged);
    _textController.removeListener(_onTextEditing);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
