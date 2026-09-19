import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_analytics_service.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_cart_drawer_controller.dart';
import 'package:matlobgo/web/v2/services/tarfa_ui_service.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_product_card.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_skeleton.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

class TarfaStoreScreen extends StatefulWidget {
  const TarfaStoreScreen({super.key, required this.storeId});

  final String storeId;

  @override
  State<TarfaStoreScreen> createState() => _TarfaStoreScreenState();
}

class _TarfaStoreScreenState extends State<TarfaStoreScreen> {
  final _catalog = CatalogService();
  final _searchController = TextEditingController();
  Store? _store;
  String _productQuery = '';
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = await _catalog.getStore(widget.storeId);
    if (!mounted || store == null) return;
    setState(() => _store = store);
    WebConversionService.instance.recordStoreVisit(store.id);
    WebAnalyticsService.instance.storeOpen(store);
    WebSeoService.instance.apply(
      title: store.name,
      description: store.description ??
          'اطلب من ${store.name} — تقييم ${store.rating}',
      canonicalPath: WebConstants.storePath(store.id),
      imageUrl: store.displayCoverUrl,
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    final q = _productQuery.trim().toLowerCase();
    var list = products.where((p) => p.isInStock).toList();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    if (_selectedSection != null && _selectedSection!.isNotEmpty) {
      list = list.where((p) => p.category == _selectedSection).toList();
    }
    return list;
  }

  Map<String, List<Product>> _groupByCategory(List<Product> products) {
    final map = <String, List<Product>>{};
    for (final p in products) {
      final key = p.category.isEmpty ? 'القائمة' : p.category;
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _StoreHero(store: store)),
        SliverToBoxAdapter(child: _StoreInfoBar(store: store)),
        if (store.discountLabel != null && store.discountLabel!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                TarfaTokens.s16,
                isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TarfaTokens.s16),
                decoration: BoxDecoration(
                  color: TarfaTokens.secondary.withValues(alpha: 0.1),
                  borderRadius: TarfaTokens.borderRadius,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: TarfaTokens.secondary,
                    ),
                    const SizedBox(width: TarfaTokens.s12),
                    Text(
                      store.discountLabel!,
                      style: TarfaTokens.titleMedium(context).copyWith(
                        color: TarfaTokens.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        StreamBuilder<List<Product>>(
          stream: _catalog.watchProducts(store),
          builder: (context, snap) {
            final allProducts = snap.data ?? [];
            final sections = _groupByCategory(
              allProducts.where((p) => p.isInStock).toList(),
            );
            final sectionKeys = sections.keys.toList();
            final filtered = _filterProducts(allProducts);

            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return SliverPadding(
                padding: EdgeInsets.all(
                  isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 3,
                    mainAxisSpacing: TarfaTokens.s16,
                    crossAxisSpacing: TarfaTokens.s16,
                    childAspectRatio: TarfaTokens.productGridAspectRatio(isMobile),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const TarfaSkeleton(
                      width: double.infinity,
                      height: 280,
                    ),
                    childCount: 6,
                  ),
                ),
              );
            }

            return SliverMainAxisGroup(
              slivers: [
                if (sectionKeys.length > 1)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySectionsDelegate(
                      sections: sectionKeys,
                      selected: _selectedSection,
                      onSelected: (s) =>
                          setState(() => _selectedSection = s),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                      TarfaTokens.s16,
                      isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                      0,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _productQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث في قائمة ${store.name}',
                        hintStyle: TarfaTokens.bodyMedium(context),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'لا توجد منتجات',
                        style: TarfaTokens.bodyLarge(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                      TarfaTokens.s16,
                      isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
                      TarfaTokens.s80,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : 3,
                        mainAxisSpacing: TarfaTokens.s24,
                        crossAxisSpacing: TarfaTokens.s24,
                        childAspectRatio: TarfaTokens.productGridAspectRatio(isMobile),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filtered[index];
                          return TarfaProductCard(
                            store: store,
                            product: product,
                            onTap: () => context.push(
                              WebConstants.productPath(store.id, product.id),
                            ),
                            onAdd: () {
                              final ok = WebCartService.instance.addProduct(
                                store: store,
                                product: product,
                              );
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'المتجر مغلق حالياً — لا يمكن الطلب الآن',
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ),
                                );
                                return;
                              }
                              TarfaCartDrawerController.instance.open();
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;

    return SizedBox(
      height: isMobile ? 220 : 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TarfaWebImage(
            kind: TarfaImageKind.storeCover,
            fill: true,
            imageUrl: store.displayCoverUrl,
            thumbnailUrl: store.displayCoverThumbUrl,
            useFullResolution: true,
            fallback: ColoredBox(
              color: TarfaTokens.primary.withValues(alpha: 0.1),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Positioned(
            top: TarfaTokens.s16,
            right: TarfaTokens.s16,
            child: IconButton(
              onPressed: () => context.pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreInfoBar extends StatelessWidget {
  const _StoreInfoBar({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;
    final padding = isMobile ? TarfaTokens.s16 : TarfaTokens.s48;

    return Transform.translate(
      offset: const Offset(0, -32),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Container(
          padding: const EdgeInsets.all(TarfaTokens.s24),
          decoration: BoxDecoration(
            color: TarfaTokens.surface,
            borderRadius: TarfaTokens.borderRadiusLg,
            boxShadow: TarfaTokens.shadowMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: TarfaTokens.borderRadius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: TarfaTokens.divider),
                    borderRadius: TarfaTokens.borderRadius,
                  ),
                  child: TarfaWebImage(
                    kind: TarfaImageKind.storeLogo,
                    width: 72,
                    height: 72,
                    imageUrl: store.displayLogoUrl,
                    thumbnailUrl: store.displayLogoThumbUrl,
                  ),
                ),
              ),
              const SizedBox(width: TarfaTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: TarfaTokens.headlineMedium(context),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: TarfaFavoritesService.instance,
                          builder: (context, _) {
                            final fav = TarfaFavoritesService.instance
                                .isFavorite(store.id);
                            return IconButton(
                              onPressed: () => TarfaFavoritesService.instance
                                  .toggle(store.id),
                              icon: Icon(
                                fav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: fav
                                    ? TarfaTokens.error
                                    : TarfaTokens.textMuted,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: TarfaTokens.s8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 18,
                        ),
                        const SizedBox(width: TarfaTokens.s4),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: TarfaTokens.labelLarge(context),
                        ),
                        const SizedBox(width: TarfaTokens.s16),
                        _InfoPill(
                          icon: Icons.schedule_rounded,
                          label: '${store.deliveryMinutes} دقيقة',
                        ),
                        const SizedBox(width: TarfaTokens.s8),
                        _InfoPill(
                          icon: Icons.delivery_dining_rounded,
                          label: store.deliveryFee == 0
                              ? 'توصيل مجاني'
                              : '${store.deliveryFee.toStringAsFixed(0)} ج.م',
                        ),
                      ],
                    ),
                    const SizedBox(height: TarfaTokens.s8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TarfaTokens.s12,
                        vertical: TarfaTokens.s4,
                      ),
                      decoration: BoxDecoration(
                        color: store.isOpen
                            ? TarfaTokens.success.withValues(alpha: 0.1)
                            : TarfaTokens.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        store.isOpen ? 'مفتوح الآن' : 'مغلق حالياً',
                        style: TarfaTokens.labelMedium(context).copyWith(
                          color: store.isOpen
                              ? TarfaTokens.success
                              : TarfaTokens.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: TarfaTokens.textMuted),
        const SizedBox(width: TarfaTokens.s4),
        Text(label, style: TarfaTokens.bodyMedium(context)),
      ],
    );
  }
}

class _StickySectionsDelegate extends SliverPersistentHeaderDelegate {
  _StickySectionsDelegate({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sections;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: TarfaTokens.background,
      elevation: overlapsContent ? 2 : 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: TarfaTokens.s16,
          vertical: TarfaTokens.s8,
        ),
        child: Row(
          children: [
            _SectionChip(
              label: 'الكل',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final section in sections)
              _SectionChip(
                label: section,
                selected: selected == section,
                onTap: () => onSelected(section),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySectionsDelegate oldDelegate) =>
      oldDelegate.sections != sections || oldDelegate.selected != selected;
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: TarfaTokens.s8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: TarfaTokens.secondary.withValues(alpha: 0.12),
        checkmarkColor: TarfaTokens.secondary,
        labelStyle: TarfaTokens.labelMedium(context).copyWith(
          color: selected ? TarfaTokens.secondary : TarfaTokens.textSecondary,
        ),
        backgroundColor: TarfaTokens.surface,
        side: BorderSide.none,
      ),
    );
  }
}
