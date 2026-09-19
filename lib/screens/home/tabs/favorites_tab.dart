import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/ui_polish_tokens.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/staggered_fade_in.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/screens/home/product/product_details_navigation.dart';
import 'package:matlobgo/screens/home/store_detail_screen.dart';
import 'package:matlobgo/screens/home/widgets/home_bottom_nav.dart';
import 'package:matlobgo/screens/home/widgets/polish/polish_skeleton.dart';
import 'package:matlobgo/screens/home/widgets/polish/polished_favorites_widgets.dart';
import 'package:matlobgo/screens/home/widgets/polish/polished_search_widgets.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/favorites_service.dart';

class _FavoriteProductEntry {
  const _FavoriteProductEntry({
    required this.product,
    required this.store,
  });

  final Product product;
  final Store store;
}

/// شاشة المفضلة — متاجر + منتجات من البيانات الحقيقية.
class FavoritesTab extends StatefulWidget {
  const FavoritesTab({
    super.key,
    required this.governorateName,
    required this.cartService,
    this.onExploreStores,
  });

  final String governorateName;
  final CartService cartService;
  final ValueChanged<HomeTab>? onExploreStores;

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final _storeRepo = StoreRepository();
  final _productRepo = ProductRepository();

  List<Store> _stores = const [];
  List<_FavoriteProductEntry> _products = const [];
  List<String> _missingStoreIds = const [];
  bool _loading = true;
  String? _error;
  String _lastSignature = '';

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_onFavoritesChanged);
    unawaited(_reload());
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    final fav = FavoritesService.instance;
    final signature =
        '${fav.ids.join(',')}|${fav.productKeys.join(',')}';
    if (signature == _lastSignature) {
      // تحديث فوري للقائمة عند الإزالة بدون إعادة جلب كاملة إن أمكن
      setState(() {
        _stores = _stores.where((s) => fav.isFavorite(s.id)).toList();
        _products = _products
            .where(
              (e) => fav.isProductFavorite(e.product.storeId, e.product.id),
            )
            .toList();
        _missingStoreIds =
            _missingStoreIds.where(fav.isFavorite).toList();
      });
      return;
    }
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final fav = FavoritesService.instance;
    if (!fav.isInitialized) await fav.init();

    final storeIds = fav.ids;
    final productRefs = fav.productRefs;
    _lastSignature = '${storeIds.join(',')}|${fav.productKeys.join(',')}';

    if (storeIds.isEmpty && productRefs.isEmpty) {
      if (!mounted) return;
      setState(() {
        _stores = const [];
        _products = const [];
        _missingStoreIds = const [];
        _loading = false;
        _error = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final storeCache = <String, Store?>{};

      Future<Store?> storeOf(String id) async {
        if (storeCache.containsKey(id)) return storeCache[id];
        final s = await _storeRepo.getStore(id);
        storeCache[id] = s;
        return s;
      }

      final stores = <Store>[];
      final missing = <String>[];
      for (final id in storeIds) {
        final store = await storeOf(id);
        if (store != null) {
          stores.add(store);
        } else {
          missing.add(id);
        }
      }
      stores.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        return a.name.compareTo(b.name);
      });

      final products = <_FavoriteProductEntry>[];
      for (final ref in productRefs) {
        final product = await _productRepo.getProduct(
          storeId: ref.$1,
          productId: ref.$2,
        );
        if (product == null) continue;
        final store = await storeOf(ref.$1);
        if (store == null) continue;
        products.add(_FavoriteProductEntry(product: product, store: store));
      }

      if (!mounted) return;
      setState(() {
        _stores = stores;
        _products = products;
        _missingStoreIds = missing;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل المفضلة — حاول مرة أخرى';
      });
    }
  }

  void _explore() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onExploreStores?.call(HomeTab.home);
  }

  String _headerLabel(int total, int stores, int products) {
    if (total == 0) return 'موردوك ومنتجاتك المحفوظة';
    final parts = <String>[];
    if (stores > 0) parts.add('$stores متجر');
    if (products > 0) parts.add('$products منتج');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canPop = Navigator.of(context).canPop();
    final fav = FavoritesService.instance;
    final total = fav.totalCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: ColoredBox(
        color: UiPolishTokens.navy,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: top),
              child: ListenableBuilder(
                listenable: FavoritesService.instance,
                builder: (context, _) {
                  final f = FavoritesService.instance;
                  return FavoritesPolishHeader(
                    count: f.totalCount,
                    countLabel: _headerLabel(
                      f.totalCount,
                      f.storeCount,
                      f.productCount,
                    ),
                    leading: canPop
                        ? Material(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            child: IconButton(
                              tooltip: 'رجوع',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: PremiumBackground.body(
                  context,
                  _buildBody(total: total),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required int total}) {
    if (_loading && _stores.isEmpty && _products.isEmpty) {
      return const PolishListSkeleton(count: 4, itemHeight: 200);
    }

    if (_error != null && _stores.isEmpty && _products.isEmpty) {
      return AppEmptyState.preset(
        AppEmptyKind.retry,
        title: _error,
        onAction: _reload,
      );
    }

    if (total == 0 || (_stores.isEmpty && _products.isEmpty && _missingStoreIds.isEmpty)) {
      return AppEmptyState.preset(
        AppEmptyKind.favorites,
        title: 'ابدأ بإضافة متاجرك المفضلة',
        subtitle: 'احفظ المتاجر والمنتجات التي تعجبك لتصل إليها بضغطة واحدة',
        onAction: _explore,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          UiPolishTokens.spaceMd,
          UiPolishTokens.spaceMd,
          UiPolishTokens.spaceMd,
          UiPolishTokens.spaceLg + 24,
        ),
        children: [
          if (_stores.isNotEmpty) ...[
            PolishSectionHeader(
              title: 'المتاجر',
              subtitle: '${_stores.length} محفوظ',
            ),
            const SizedBox(height: UiPolishTokens.spaceSm),
            ...List.generate(_stores.length, (i) {
              final store = _stores[i];
              final featured = i == 0 && _stores.length > 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: UiPolishTokens.spaceSm),
                child: StaggeredFadeIn(
                  index: i,
                  child: PolishedFavoriteCard(
                    store: store,
                    featured: featured,
                    onTap: () => openStoreDetail(
                      context,
                      store: store,
                      cartService: widget.cartService,
                    ),
                    onRemoved: (s) => showFavoriteUndoSnackBar(context, s),
                  ),
                ),
              );
            }),
          ],
          if (_products.isNotEmpty) ...[
            if (_stores.isNotEmpty)
              const SizedBox(height: UiPolishTokens.spaceMd),
            PolishSectionHeader(
              title: 'المنتجات',
              subtitle: '${_products.length} محفوظ',
            ),
            const SizedBox(height: UiPolishTokens.spaceSm),
            ...List.generate(_products.length, (i) {
              final entry = _products[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: UiPolishTokens.spaceSm),
                child: StaggeredFadeIn(
                  index: _stores.length + i,
                  child: PolishedFavoriteProductCard(
                    product: entry.product,
                    storeName: entry.store.name,
                    onTap: () => openProductDetail(
                      context,
                      store: entry.store,
                      product: entry.product,
                      relatedProducts: const [],
                      cartService: widget.cartService,
                    ),
                    onRemove: () async {
                      await FavoritesService.instance.removeProduct(
                        entry.product.storeId,
                        entry.product.id,
                      );
                      if (!mounted) return;
                      showFavoriteProductUndoSnackBar(
                        context,
                        storeId: entry.product.storeId,
                        productId: entry.product.id,
                        productName: entry.product.name,
                      );
                    },
                  ),
                ),
              );
            }),
          ],
          if (_missingStoreIds.isNotEmpty) ...[
            const SizedBox(height: UiPolishTokens.spaceMd),
            PolishSectionHeader(
              title: 'غير متاح حالياً',
              subtitle: 'متاجر لم تعد ظاهرة في الكتالوج',
            ),
            const SizedBox(height: UiPolishTokens.spaceSm),
            ..._missingStoreIds.map((id) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      Icons.store_mall_directory_outlined,
                      color: AppColors.textHint,
                    ),
                    title: Text(
                      'متجر غير متاح',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      id,
                      style: GoogleFonts.cairo(fontSize: 11),
                    ),
                    trailing: TextButton(
                      onPressed: () => FavoritesService.instance.remove(id),
                      child: Text(
                        'إزالة',
                        style: GoogleFonts.cairo(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
