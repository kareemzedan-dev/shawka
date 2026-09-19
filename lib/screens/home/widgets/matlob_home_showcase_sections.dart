import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/theme/home_typography.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/core/widgets/shimmer_effect.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/widgets/home_hero.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_feed.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_ui_primitives.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/services/favorites_service.dart';

// ─── Featured stores (الموردون المميزون) ──────────────────────────────────────

class MatlobFeaturedStoresSection extends StatelessWidget {
  const MatlobFeaturedStoresSection({
    super.key,
    required this.stores,
    required this.onStoreTap,
    this.title = 'الموردون المميزون',
    this.viewAllLabel = 'عرض الكل',
    this.onViewAll,
  });

  final List<Store> stores;
  final void Function(Store store) onStoreTap;
  final String title;
  final String viewAllLabel;
  final VoidCallback? onViewAll;

  static const double listHeight = 228;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();

    final cardWidth = (MediaQuery.sizeOf(context).width * 0.78).clamp(
      250.0,
      340.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTheme.pageHorizontal,
          ),
          child: MatlobSectionHeader(
            title: title,
            actionLabel: viewAllLabel,
            onAction: onViewAll,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: HomeTheme.pageHorizontal,
            ),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final store = stores[index];
              return MatlobFadeIn(
                delay: Duration(milliseconds: 50 * index.clamp(0, 4)),
                child: MatlobFeaturedStoreCard(
                  store: store,
                  width: cardWidth,
                  onTap: () => onStoreTap(store),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// بطاقة مورد مميز — غلاف، شعار، حالة، مفضلة، توثيق، تقييم، توصيل.
class MatlobFeaturedStoreCard extends StatelessWidget {
  const MatlobFeaturedStoreCard({
    super.key,
    required this.store,
    required this.width,
    this.onTap,
  });

  final Store store;
  final double width;
  final VoidCallback? onTap;

  static const double _imageHeight = 138;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: 'متجر ${store.name}',
        child: MatlobPressableScale(
          onTap: onTap,
          enabled: store.isOpen,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: MatlobHomeColors.lightCardShadow,
            ),
            padding: const EdgeInsets.all(12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCover(),
                    const SizedBox(height: 12),
                    _buildInfo(context),
                  ],
                ),
                // شعار المتجر — دائرة بيضاء تتراكب على حافة الغلاف السفلية.
                PositionedDirectional(
                  top: _imageHeight - 24,
                  end: 14,
                  child: _StoreLogoCircle(store: store),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return SizedBox(
      height: _imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CatalogNetworkImage(
              imageUrl: store.displayHeroImageUrl,
              thumbnailUrl: store.displayHeroThumbUrl,
              fit: BoxFit.cover,
              cacheWidth: 680,
              cacheHeight: 360,
              fallback: SafeAssetImage(
                asset: AppAssets.categoryFallback,
                fallbackIcon: store.categoryIcon,
              ),
            ),
            PositionedDirectional(
              top: 10,
              start: 10,
              child: _OpenStatusBadge(isOpen: store.isOpen),
            ),
            // إزاحة 5 + حشوة 5 داخل الزر = نفس الموضع البصري (10) مع منطقة
            // لمس أكبر (44px) دون تغيير الحجم المرئي.
            PositionedDirectional(
              top: 5,
              end: 5,
              child: _FavoriteButton(storeId: store.id),
            ),
            if (store.discountLabel != null &&
                store.discountLabel!.trim().isNotEmpty)
              PositionedDirectional(
                bottom: 10,
                start: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    store.discountLabel!.trim(),
                    style: HomeTypography.style(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    height: 1.2,
                  ),
                ),
              ),
              if (store.isFeatured) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.verified_rounded,
                  size: 17,
                  color: MatlobHomeColors.verifiedBlue,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // ⭐ التقييم · 🚴 التوصيل · 🕒 الوقت — سطر واحد متوازن.
          MatlobStoreMetaRow(store: store),
        ],
      ),
    );
  }
}

class _StoreLogoCircle extends StatelessWidget {
  const _StoreLogoCircle({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: store.displayLogoUrl != null
          ? CatalogNetworkImage(
              imageUrl: store.displayLogoUrl,
              thumbnailUrl: store.displayLogoThumbUrl,
              fit: BoxFit.cover,
              cacheWidth: 96,
              cacheHeight: 96,
              fallback: _iconFallback(),
            )
          : _iconFallback(),
    );
  }

  Widget _iconFallback() {
    return Center(
      child: Icon(store.categoryIcon, size: 20, color: AppColors.primary),
    );
  }
}

class _OpenStatusBadge extends StatelessWidget {
  const _OpenStatusBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? MatlobHomeColors.openBadgeBg : const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isOpen ? 'مفتوح' : 'مغلق حالياً',
        style: HomeTypography.style(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// زر مفضلة — تحديث متفائل فوري عبر FavoritesService.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final isFav = FavoritesService.instance.isFavorite(storeId);
        return Semantics(
          button: true,
          label: isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              unawaited(FavoritesService.instance.toggle(storeId));
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.all(5),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(isFav),
                  size: 18,
                  color: isFav ? AppColors.primary : AppColors.navy,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Popular products (الأكثر طلباً) ────────────────────────────────────────

/// عنصر عرض: منتج مع متجره — لبطاقات «الأكثر طلباً».
class PopularProductItem {
  const PopularProductItem({required this.store, required this.product});

  final Store store;
  final Product product;
}

/// يجمع أشهر المنتجات من أفضل المتاجر عبر طبقة الـ Repository (بدون Firestore
/// مباشرة في الـ UI) — يعرض حالات التحميل والخطأ والفراغ لكل القسم.
class MatlobPopularProductsSection extends StatefulWidget {
  const MatlobPopularProductsSection({
    super.key,
    required this.stores,
    required this.onProductTap,
    this.title = 'الأكثر طلباً',
    this.viewAllLabel = 'عرض الكل',
    this.onViewAll,
    this.maxStores = 8,
    this.maxPerStore = 3,
  });

  /// المتاجر المرشحة (الأعلى تقييماً/المميزة) — بحد أقصى ثابت لتفادي N+1
  /// غير محدود حتى تتوفر حقول governorate/storeId على مستندات المنتجات.
  final List<Store> stores;
  final void Function(Store store, Product product, List<Product> related)
  onProductTap;
  final String title;
  final String viewAllLabel;
  final VoidCallback? onViewAll;
  final int maxStores;
  final int maxPerStore;

  @override
  State<MatlobPopularProductsSection> createState() =>
      _MatlobPopularProductsSectionState();
}

class _MatlobPopularProductsSectionState
    extends State<MatlobPopularProductsSection> {
  final _catalog = CatalogService();
  final Map<String, List<Product>> _productsByStore = {};
  final Map<String, StreamSubscription<List<Product>>> _subs = {};
  bool _hasError = false;

  List<Store> get _sourceStores =>
      widget.stores.where((s) => s.isOpen).take(widget.maxStores).toList();

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant MatlobPopularProductsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.stores.map((s) => s.id).join(',');
    final newIds = widget.stores.map((s) => s.id).join(',');
    if (oldIds != newIds) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    _hasError = false;
    unawaited(() async {
      String? activityTypeId;
      try {
        activityTypeId =
            (await AuthService().getCurrentAppUser())?.activityTypeId;
      } catch (_) {
        activityTypeId = null;
      }
      if (!mounted) return;
      for (final store in _sourceStores) {
        _subs[store.id] = _catalog
            .watchProducts(store, activityTypeId: activityTypeId)
            .listen(
              (products) {
                if (!mounted) return;
                setState(() {
                  _productsByStore[store.id] = products;
                  _hasError = false;
                });
              },
              onError: (_) {
                if (!mounted) return;
                setState(() => _hasError = true);
              },
            );
      }
    }());
  }

  void _unsubscribe() {
    for (final sub in _subs.values) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    _productsByStore.clear();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  List<PopularProductItem> _buildItems() {
    final items = <PopularProductItem>[];
    for (final store in _sourceStores) {
      final products = _productsByStore[store.id];
      if (products == null) continue;

      final inStock = products.where((p) => p.isInStock).toList();
      if (inStock.isEmpty) continue;

      final highlighted = inStock
          .where((p) => p.bestSeller || p.isFeatured)
          .toList();
      final pool = highlighted.isNotEmpty ? highlighted : inStock;
      pool.sort((a, b) {
        final bestSeller =
            (b.bestSeller ? 1 : 0).compareTo(a.bestSeller ? 1 : 0);
        if (bestSeller != 0) return bestSeller;
        final featured =
            (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
        if (featured != 0) return featured;
        final hasImage = ((b.imageUrl?.trim().isNotEmpty ?? false) ? 1 : 0)
            .compareTo((a.imageUrl?.trim().isNotEmpty ?? false) ? 1 : 0);
        if (hasImage != 0) return hasImage;
        return a.sortOrder.compareTo(b.sortOrder);
      });

      for (final p in pool.take(widget.maxPerStore)) {
        items.add(PopularProductItem(store: store, product: p));
      }
    }

    // المنتجات المفعّلة كـ «الأكثر طلباً» أولاً عبر كل الموردين.
    items.sort((a, b) {
      final pinned =
          (b.product.bestSeller ? 1 : 0).compareTo(a.product.bestSeller ? 1 : 0);
      if (pinned != 0) return pinned;
      return a.product.sortOrder.compareTo(b.product.sortOrder);
    });
    return items;
  }

  bool get _isLoading =>
      _sourceStores.isNotEmpty &&
      _productsByStore.length < _subs.length &&
      !_hasError;

  void _retry() {
    _unsubscribe();
    setState(_subscribe);
  }

  @override
  Widget build(BuildContext context) {
    if (_sourceStores.isEmpty) return const SizedBox.shrink();

    final items = _buildItems();
    // عرض بطاقتين كاملتين في الشاشة كما في التصميم.
    final available =
        MediaQuery.sizeOf(context).width - HomeTheme.pageHorizontal * 2;
    final cardWidth = ((available - 12) / 2).clamp(140.0, 220.0);

    Widget body;
    if (_isLoading && items.isEmpty) {
      body = _PopularProductsSkeleton(cardWidth: cardWidth);
    } else if (_hasError && items.isEmpty) {
      body = _SectionErrorState(onRetry: _retry);
    } else if (items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeTheme.pageHorizontal,
        ),
        child: Text(
          'فعّل منتجات من لوحة التحكم لتظهر هنا',
          style: HomeTypography.style(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else {
      body = SizedBox(
        height: 218,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTheme.pageHorizontal,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return MatlobFadeIn(
              delay: Duration(milliseconds: 40 * index.clamp(0, 5)),
              child: MatlobPopularProductCard(
                item: item,
                width: cardWidth,
                onTap: () {
                  final related = (_productsByStore[item.store.id] ?? [])
                      .where((p) => p.id != item.product.id && p.isInStock)
                      .toList();
                  widget.onProductTap(item.store, item.product, related);
                },
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTheme.pageHorizontal,
          ),
          child: MatlobSectionHeader(
            title: widget.title,
            accented: true,
          ),
        ),
        const SizedBox(height: 12),
        body,
        const SizedBox(height: 16),
      ],
    );
  }
}

/// بطاقة منتج — صورة، Badge، اسم الطبق، اسم المتجر، السعر، زر إضافة.
class MatlobPopularProductCard extends StatelessWidget {
  const MatlobPopularProductCard({
    super.key,
    required this.item,
    required this.width,
    this.onTap,
  });

  final PopularProductItem item;
  final double width;
  final VoidCallback? onTap;

  String? get _badgeLabel => item.product.badgeLabel;

  void _addToCart(BuildContext context) {
    HapticFeedback.mediumImpact();
    final ok = CartService.instance.addProduct(
      store: item.store,
      product: item.product,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'تمت إضافة ${item.product.name} إلى السلة'
                : 'المتجر مغلق حالياً — لا يمكن الطلب الآن',
            style: HomeTypography.style(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          backgroundColor: ok ? AppColors.navy : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: '${product.name} من ${item.store.name}',
        child: MatlobPressableScale(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: MatlobHomeColors.lightCardShadow,
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CatalogNetworkImage(
                          imageUrl: product.imageUrl,
                          thumbnailUrl: product.imageThumbUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                          cacheHeight: 300,
                          fallback: ColoredBox(
                            color: AppColors.surfaceMuted,
                            child: Icon(
                              Icons.storefront_rounded,
                              size: 28,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        if (_badgeLabel != null)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _badgeLabel!,
                                style: HomeTypography.style(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        if (!product.isInStock)
                          ColoredBox(
                            color: AppColors.navy.withValues(alpha: 0.55),
                            child: Center(
                              child: Text(
                                'نفد المخزون',
                                style: HomeTypography.style(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeTypography.style(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${product.price.toInt()} ج.م',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HomeTypography.style(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (product.oldPrice > product.price) ...[
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${product.oldPrice.toInt()} ج',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          HomeTypography.style(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textHint,
                                            height: 1.2,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _AddToCartButton(
                            enabled: product.isInStock,
                            onTap: () => _addToCart(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// زر إضافة للسلة — دائرة كحلية مع أنيميشن ضغط.
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.onTap, this.enabled = true});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'إضافة إلى السلة',
      child: MatlobPressableScale(
        onTap: enabled ? onTap : null,
        enabled: enabled,
        // حشوة شفافة توسّع منطقة اللمس دون تغيير الحجم المرئي.
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: enabled ? AppColors.navy : AppColors.surfaceMuted,
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_rounded,
              size: 18,
              color: enabled ? AppColors.white : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularProductsSkeleton extends StatelessWidget {
  const _PopularProductsSkeleton({required this.cardWidth});

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: HomeTheme.pageHorizontal,
        ),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) =>
            ShimmerBox(width: cardWidth, height: 218, borderRadius: 20),
      ),
    );
  }
}

/// حالة خطأ بمستوى القسم — رسالة ودّية + زر إعادة المحاولة.
class _SectionErrorState extends StatelessWidget {
  const _SectionErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            'تعذّر تحميل هذا القسم',
            style: HomeTypography.style(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'إعادة المحاولة',
              style: HomeTypography.style(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
