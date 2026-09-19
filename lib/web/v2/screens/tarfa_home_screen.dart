import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/widgets/governorate_picker.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/shared/home/home_catalog_sections.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_live_stats_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_category_grid.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_footer.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_hero.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_promo_slider.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_section_header.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_skeleton.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_store_card.dart';

/// Premium web home — v2 design, live Firestore data (same as mobile app).
class TarfaHomeScreen extends StatefulWidget {
  const TarfaHomeScreen({super.key, this.govId});

  final String? govId;

  @override
  State<TarfaHomeScreen> createState() => _TarfaHomeScreenState();
}

class _TarfaHomeScreenState extends State<TarfaHomeScreen> {
  final _catalog = CatalogService();
  final _config = AppConfigService.instance;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _syncGovernorate();
    _config.addListener(_onSettings);
    WebSeoService.instance.apply(
      title: 'اطلب كل شيء — ${WebGovernorateService.instance.governorateName}',
      description: AppBranding.liveDataFromBrand(
        WebGovernorateService.instance.governorateName,
      ),
      canonicalPath: WebConstants.governoratePath(
        widget.govId ?? WebGovernorateService.instance.governorateId,
      ),
    );
  }

  @override
  void dispose() {
    _config.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    WebLiveStats.instance.onSettingsUpdated();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(TarfaHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.govId != widget.govId) _syncGovernorate();
  }

  Future<void> _syncGovernorate() async {
    final id = widget.govId;
    if (id != null) {
      await WebGovernorateService.instance.setGovernorateById(id);
    }
    WebLiveStats.instance.bindGovernorate(
      WebGovernorateService.instance.governorateName,
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickGovernorate() async {
    final picked = await showGovernoratePicker(
      context,
      current: WebGovernorateService.instance.governorate,
    );
    if (picked == null || !mounted) return;
    await WebGovernorateService.instance.setGovernorate(picked);
    if (!mounted) return;
    context.go(WebConstants.governoratePath(picked.id));
  }

  void _openSearch([String? query]) {
    final path =
        '${WebConstants.governoratePath(WebGovernorateService.instance.governorateId)}/search';
    if (query != null && query.isNotEmpty) {
      context.push('$path?q=${Uri.encodeComponent(query)}');
    } else {
      context.push(path);
    }
  }

  void _openStore(Store store) {
    if (!store.isActive) return;
    WebConversionService.instance.recordStoreVisit(store.id);
    context.push(WebConstants.storePath(store.id));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= TarfaTokens.mobileBreakpoint;
    final isMobile = !isDesktop;

    return ListenableBuilder(
      listenable: WebGovernorateService.instance,
      builder: (context, _) {
        final govName = WebGovernorateService.instance.governorateName;
        final hPad = isMobile ? TarfaTokens.s16 : TarfaTokens.s40;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            if (isMobile)
              SliverToBoxAdapter(
                child: TarfaHero(
                  locationLabel: govName,
                  onLocationTap: _pickGovernorate,
                  onSearchTap: () => _openSearch(),
                  onSearchSubmit: _openSearch,
                  onCategoryTap: (id) => context.push(
                    WebConstants.categoryPath(
                      WebGovernorateService.instance.governorateId,
                      id,
                    ),
                  ),
                ),
              ),
            if (isDesktop)
              SliverToBoxAdapter(
                child: _DesktopWelcomeStrip(
                  governorate: govName,
                  onLocationTap: _pickGovernorate,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, TarfaTokens.s32, hPad, 0),
              sliver: SliverToBoxAdapter(
                child: StreamBuilder<List<PromoBanner>>(
                  stream: _config.watchPromoBanners(govName),
                  builder: (context, bannerSnap) {
                    final banners = bannerSnap.data ?? [];
                    if (banners.isEmpty) return const SizedBox.shrink();
                    // Warm browser cache for above-the-fold promo art.
                    Future.microtask(
                      () => CatalogNetworkImage.prefetch([
                        for (final b in banners) ...[b.imageUrl, b.imageThumbUrl],
                      ]),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TarfaSectionHeader(
                          title: 'عروض حصرية',
                          subtitle: 'وفّر أكثر مع أحدث العروض في منطقتك',
                        ),
                        TarfaPromoSlider(banners: banners),
                        const SizedBox(height: TarfaTokens.s48),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: SliverToBoxAdapter(
                child: StreamBuilder<List<StoreCategoryDef>>(
                  stream: _catalog.watchCategories(govName),
                  builder: (context, catSnap) {
                    final categories = (catSnap.data ?? [])
                        .where((c) => c.isActive)
                        .toList()
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TarfaSectionHeader(
                          title: 'تصفّح حسب التصنيف',
                          subtitle: 'موردون ومنتجات متنوعة',
                          actionLabel: 'عرض الكل',
                          onAction: () => context.go(
                            WebConstants.storesPath(
                              WebGovernorateService.instance.governorateId,
                            ),
                          ),
                        ),
                        if (catSnap.connectionState == ConnectionState.waiting &&
                            !catSnap.hasData)
                          const TarfaSkeleton(
                            width: double.infinity,
                            height: 148,
                          )
                        else
                          TarfaCategoryGrid(
                            categories: categories,
                            selectedId: _selectedCategoryId,
                            onCategoryTap: (cat) {
                              context.push(
                                WebConstants.categoryPath(
                                  WebGovernorateService.instance.governorateId,
                                  cat.id,
                                ),
                              );
                            },
                            onMoreTap: () => context.go(
                              WebConstants.storesPath(
                                WebGovernorateService.instance.governorateId,
                              ),
                            ),
                          ),
                        const SizedBox(height: TarfaTokens.s48),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: StreamBuilder<List<Store>>(
                stream: _catalog.watchStores(governorate: govName),
                builder: (context, storeSnap) {
                  final allStores = storeSnap.data ?? [];
                  final featured = HomeCatalogSections.featured(allStores);
                  final trending = HomeCatalogSections.trending(
                    allStores,
                    featured,
                  );

                  if (storeSnap.connectionState == ConnectionState.waiting &&
                      !storeSnap.hasData) {
                    return SliverToBoxAdapter(
                      child: _StoreGridSkeleton(isMobile: isMobile),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    WebLiveStats.instance.onStoresUpdated(allStores);
                  });

                  return SliverMainAxisGroup(
                    slivers: [
                      if (featured.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: TarfaSectionHeader(
                            title: '⭐ متاجر مميزة',
                            subtitle: 'اختيارات مميزة لك',
                            actionLabel: 'عرض الكل',
                            onAction: () => context.go(
                              WebConstants.storesPath(
                                WebGovernorateService.instance.governorateId,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: isMobile ? 280 : 320,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.only(bottom: TarfaTokens.s8),
                              itemCount: featured.length.clamp(0, 10),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: TarfaTokens.s24),
                              itemBuilder: (context, i) => SizedBox(
                                width: isMobile ? 260 : 300,
                                child: TarfaStoreCard(
                                  store: featured[i],
                                  onTap: () => _openStore(featured[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: TarfaTokens.s48),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: TarfaSectionHeader(
                          title: '🔥 الأكثر طلباً',
                          subtitle: 'متاجر يحبها عملاؤنا في $govName',
                          actionLabel: 'عرض الكل',
                          onAction: () => context.go(
                            WebConstants.storesPath(
                              WebGovernorateService.instance.governorateId,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _StoreGrid(
                          stores: trending,
                          isMobile: isMobile,
                          onStoreTap: _openStore,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: TarfaTokens.s48),
                      ),
                      SliverToBoxAdapter(
                        child: TarfaSectionHeader(
                          title: 'كل المتاجر',
                          subtitle: 'تصفّح جميع المتاجر المتاحة للتوصيل',
                          actionLabel: 'عرض الكل',
                          onAction: () => context.go(
                            WebConstants.storesPath(
                              WebGovernorateService.instance.governorateId,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _StoreGrid(
                          stores: StoreCatalogUtils.filterStores(allStores),
                          isMobile: isMobile,
                          onStoreTap: _openStore,
                          maxItems: isMobile ? 8 : 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: TarfaFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: TarfaTokens.s80)),
          ],
        );
      },
    );
  }
}

class _DesktopWelcomeStrip extends StatelessWidget {
  const _DesktopWelcomeStrip({
    required this.governorate,
    required this.onLocationTap,
  });

  final String governorate;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TarfaTokens.s40,
        TarfaTokens.s32,
        TarfaTokens.s40,
        TarfaTokens.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كل اللي تحتاجه... يوصلك في دقائق',
                  style: TarfaTokens.headlineLarge(context),
                ),
                const SizedBox(height: TarfaTokens.s8),
                Text(
                  'اطلب من أفضل المتاجر في $governorate',
                  style: TarfaTokens.bodyLarge(context),
                ),
              ],
            ),
          ),
          Material(
            color: TarfaTokens.surface,
            borderRadius: TarfaTokens.borderRadius,
            elevation: 0,
            shadowColor: TarfaTokens.primary.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onLocationTap,
              borderRadius: TarfaTokens.borderRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TarfaTokens.s24,
                  vertical: TarfaTokens.s12,
                ),
                decoration: BoxDecoration(
                  borderRadius: TarfaTokens.borderRadius,
                  boxShadow: TarfaTokens.shadowSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: TarfaTokens.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: TarfaTokens.s8),
                    Text(governorate, style: TarfaTokens.labelLarge(context)),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: TarfaTokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreGrid extends StatelessWidget {
  const _StoreGrid({
    required this.stores,
    required this.isMobile,
    required this.onStoreTap,
    this.maxItems,
  });

  final List<Store> stores;
  final bool isMobile;
  final ValueChanged<Store> onStoreTap;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(TarfaTokens.s32),
        child: Center(
          child: Text(
            'لا توجد متاجر متاحة حالياً',
            style: TarfaTokens.bodyLarge(context),
          ),
        ),
      );
    }

    final count = maxItems ?? stores.length;
    final items = stores.take(count).toList();
    final crossAxisCount = isMobile ? 1 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: TarfaTokens.s24,
        crossAxisSpacing: TarfaTokens.s24,
        childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final store = items[index];
        return TarfaStoreCard(
          store: store,
          onTap: () => onStoreTap(store),
        );
      },
    );
  }
}

class _StoreGridSkeleton extends StatelessWidget {
  const _StoreGridSkeleton({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        mainAxisSpacing: TarfaTokens.s24,
        crossAxisSpacing: TarfaTokens.s24,
        childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
      ),
      itemCount: isMobile ? 3 : 6,
      itemBuilder: (_, _) => const TarfaStoreCardSkeleton(),
    );
  }
}
