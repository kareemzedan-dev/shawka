import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/screens/home/product_detail_screen.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/screens/home/widgets/matlob_store_detail_ui.dart';

const _side = HomeTheme.pageHorizontal;
const _stickyCartHeight = 64.0;

TextStyle _cairo({
  required AppPalette palette,
  required double size,
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.cairo(
    fontSize: size,
    fontWeight: weight,
    color: color ?? palette.textPrimary,
    height: height,
    letterSpacing: letterSpacing,
  );
}

void openStoreDetail(
  BuildContext context, {
  required Store store,
  required CartService cartService,
  CatalogService? catalogService,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StoreDetailScreen(
        store: store,
        cartService: cartService,
        catalogService: catalogService,
      ),
    ),
  );
}

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({
    super.key,
    required this.store,
    required this.cartService,
    this.catalogService,
  });

  final Store store;
  final CartService cartService;
  final CatalogService? catalogService;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  ({int count, double subtotal}) _storeCartTotals() {
    var count = 0;
    var subtotal = 0.0;
    for (final item in widget.cartService.items) {
      if (item.storeId == widget.store.id) {
        count += item.quantity;
        subtotal += item.lineTotal;
      }
    }
    return (count: count, subtotal: subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalogService ?? CatalogService();
    final store = widget.store;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final palette = context.palette;
        final isDark = palette.isDark;

        return ListenableBuilder(
          listenable: widget.cartService,
          builder: (context, _) {
            final cart = _storeCartTotals();
            final showCartBar = cart.count > 0;
            final listBottomPad = showCartBar
                ? _stickyCartHeight + 20 + bottom
                : 28 + bottom;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light
                  : AppColors.lightStatusBar,
              child: Scaffold(
                backgroundColor: PremiumBackground.scaffoldColor(context),
                resizeToAvoidBottomInset: false,
                body: Stack(
                  children: [
                    _StoreMenuScrollView(
                      store: store,
                      catalog: catalog,
                      cartService: widget.cartService,
                      palette: palette,
                      listBottomPad: listBottomPad,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _StickyStoreCartBar(
                        visible: showCartBar,
                        palette: palette,
                        itemCount: cart.count,
                        subtotal: cart.subtotal,
                        bottomInset: bottom,
                        onViewCart: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// قائمة المنيو منفصلة لتقليل إعادة البناء عند الكتابة وفتح لوحة المفاتيح.
class _StoreMenuScrollView extends StatefulWidget {
  const _StoreMenuScrollView({
    required this.store,
    required this.catalog,
    required this.cartService,
    required this.palette,
    required this.listBottomPad,
  });

  final Store store;
  final CatalogService catalog;
  final CartService cartService;
  final AppPalette palette;
  final double listBottomPad;

  @override
  State<_StoreMenuScrollView> createState() => _StoreMenuScrollViewState();
}

class _StoreMenuScrollViewState extends State<_StoreMenuScrollView> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  String _menuQuery = '';
  String? _selectedCategory;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final next = _searchController.text;
      if (next == _menuQuery) return;
      setState(() => _menuQuery = next);
    });
  }

  int _qtyFor(Product product) {
    final id = '${widget.store.id}_${product.id}';
    for (final item in widget.cartService.items) {
      if (item.id == id) return item.quantity;
    }
    return 0;
  }

  void _decrement(Product product) {
    final id = '${widget.store.id}_${product.id}';
    final qty = _qtyFor(product);
    widget.cartService.updateQuantity(id, qty - 1);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  List<Product> _filterMenu(List<Product> products) {
    return filterMenuProducts(
      products: products,
      query: _menuQuery,
      category: _selectedCategory,
    );
  }

  Widget _buildProductRow({
    required Product product,
    required List<Product> products,
    required bool isLast,
  }) {
    final store = widget.store;
    final palette = widget.palette;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 5),
      child: MatlobStoreProductRow(
        key: ValueKey('store-product-${product.id}'),
        palette: palette,
        product: product,
        enabled: store.isOpen,
        quantity: _qtyFor(product),
        onOpen: () {
          openProductDetail(
            context,
            store: store,
            product: product,
            relatedProducts: products.where((p) => p.id != product.id).toList(),
            cartService: widget.cartService,
          );
        },
        onAdd: () {
          widget.cartService.addProduct(store: store, product: product);
          unawaited(
            AnalyticsService.instance.track(
              type: AnalyticsEventType.addToCart,
              screen: 'store_detail',
              label: 'إضافة ${product.name}',
              storeId: store.id,
              storeName: store.name,
              productId: product.id,
              productName: product.name,
            ),
          );
          showAuthMessage(context, 'تمت الإضافة للسلة ✓');
        },
        onDecrement: () => _decrement(product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final palette = widget.palette;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return StreamBuilder<AppUser?>(
      stream: AuthService().watchCurrentAppUser(),
      builder: (context, userSnap) {
        return StreamBuilder<List<Product>>(
          stream: widget.catalog.watchProducts(
            store,
            activityTypeId: userSnap.data?.activityTypeId,
          ),
          builder: (context, snapshot) {
            final products = dedupeProductsById(snapshot.data ?? []);
            final filtered = _filterMenu(products);
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                products.isEmpty;

            final categories = menuCategoriesFromProducts(products);
            final popular = popularMenuItems(products);
            final filteredPopular = popular
                .where((p) => filtered.any((f) => f.id == p.id))
                .toList();
            final filteredRest = filtered
                .where((p) => !filteredPopular.any((fp) => fp.id == p.id))
                .toList();
            final showPopular =
                _menuQuery.trim().isEmpty && filteredPopular.isNotEmpty;

            return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical) {
              final next = n.metrics.pixels;
              if ((next - _scrollOffset.value).abs() >= 2) {
                _scrollOffset.value = next;
              }
            }
            return false;
          },
          child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _scrollOffset,
                    builder: (context, offset, _) => MatlobStoreHeroHeader(
                      store: store,
                      palette: palette,
                      scrollOffset: offset,
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  MatlobStoreMetaSection(
                    store: store,
                    palette: palette,
                    onInfoTap: () => showMatlobStoreInfoSheet(
                      context,
                      store: store,
                      palette: palette,
                    ),
                  ),
                  MatlobStoreMenuSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    palette: palette,
                    hasActiveFilter: _selectedCategory != null,
                    onFilterTap: categories.isEmpty
                        ? null
                        : () => showMatlobStoreFilterSheet(
                              context,
                              palette: palette,
                              categories: categories,
                              selected: _selectedCategory,
                              onSelected: (value) {
                                setState(() => _selectedCategory = value);
                              },
                            ),
                  ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MatlobStoreCategoryChips(
                      categories: categories,
                      selected: _selectedCategory,
                      palette: palette,
                      onSelected: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (!store.isOpen)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    matlobStoreSide,
                    0,
                    matlobStoreSide,
                    12,
                  ),
                  child: _ClosedNotice(palette: palette),
                ),
              ),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (products.isEmpty)
              SliverToBoxAdapter(
                child: AppEmptyState.preset(
                  AppEmptyKind.menuEmpty,
                  compact: true,
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: AppEmptyState.preset(
                  AppEmptyKind.menuSearch,
                  onAction: () {
                    _searchController.clear();
                    _searchFocus.unfocus();
                    setState(() {
                      _menuQuery = '';
                      _selectedCategory = null;
                    });
                  },
                ),
              )
            else ...[
              if (showPopular) ...[
                SliverToBoxAdapter(
                  child: MatlobStoreSectionHeader(
                    title: 'الأكثر طلباً',
                    palette: palette,
                    count: filteredPopular.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: matlobStoreSide),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredPopular.length - 1 ? 0 : 10,
                        ),
                        child: MatlobStorePopularCard(
                          key: ValueKey('popular-${filteredPopular[index].id}'),
                          palette: palette,
                          product: filteredPopular[index],
                          enabled: store.isOpen,
                          quantity: _qtyFor(filteredPopular[index]),
                          onOpen: () {
                            openProductDetail(
                              context,
                              store: store,
                              product: filteredPopular[index],
                              relatedProducts: products
                                  .where((p) => p.id != filteredPopular[index].id)
                                  .toList(),
                              cartService: widget.cartService,
                            );
                          },
                          onAdd: () {
                            widget.cartService.addProduct(
                              store: store,
                              product: filteredPopular[index],
                            );
                            unawaited(
                              AnalyticsService.instance.track(
                                type: AnalyticsEventType.addToCart,
                                screen: 'store_detail',
                                label: 'إضافة ${filteredPopular[index].name}',
                                storeId: store.id,
                                storeName: store.name,
                                productId: filteredPopular[index].id,
                                productName: filteredPopular[index].name,
                              ),
                            );
                            showAuthMessage(context, 'تمت الإضافة للسلة ✓');
                          },
                          onDecrement: () =>
                              _decrement(filteredPopular[index]),
                        ),
                      ),
                      childCount: filteredPopular.length,
                    ),
                  ),
                ),
              ],
              if (filteredRest.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: MatlobStoreSectionHeader(
                    title: showPopular ? 'باقي القائمة' : 'المنيو',
                    palette: palette,
                    count: filteredRest.length,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    matlobStoreSide,
                    0,
                    matlobStoreSide,
                    widget.listBottomPad + keyboardInset,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductRow(
                        product: filteredRest[index],
                        products: products,
                        isLast: index == filteredRest.length - 1,
                      ),
                      childCount: filteredRest.length,
                    ),
                  ),
                ),
              ] else if (showPopular)
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: widget.listBottomPad + keyboardInset,
                  ),
                ),
            ],
          ],
        ),
            );
          },
        );
      },
    );
  }
}

class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: HomeTheme.borderSm,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: palette.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'المتجر مغلق حالياً — يمكنك التصفح، والطلب غير متاح',
              style: _cairo(
                palette: palette,
                size: 13,
                weight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyStoreCartBar extends StatelessWidget {
  const _StickyStoreCartBar({
    required this.visible,
    required this.palette,
    required this.itemCount,
    required this.subtotal,
    required this.bottomInset,
    required this.onViewCart,
  });

  final bool visible;
  final AppPalette palette;
  final int itemCount;
  final double subtotal;
  final double bottomInset;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: HomeTheme.animStandard,
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.2),
      child: AnimatedOpacity(
        duration: HomeTheme.animStandard,
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Padding(
            padding: EdgeInsets.fromLTRB(_side, 0, _side, 10 + bottomInset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: InkWell(
                    onTap: onViewCart,
                    splashColor: Colors.white.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.06),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            AppColors.navy.withValues(alpha: 0.94),
                            const Color(0xFF0A0A0A).withValues(alpha: 0.92),
                            AppColors.navyLight.withValues(alpha: 0.94),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.34),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: _stickyCartHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.shopping_bag_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  PositionedDirectional(
                                    top: -6,
                                    end: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.error
                                                .withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '$itemCount',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الإجمالي',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      '${subtotal.toStringAsFixed(2)} ج.م',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'عرض السلة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 14,
                                      color: AppColors.navy
                                          .withValues(alpha: 0.85),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
