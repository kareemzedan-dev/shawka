import 'package:flutter/material.dart';

import 'package:matlobgo/core/theme/home_theme.dart';

import 'package:matlobgo/core/utils/store_catalog_utils.dart';

import 'package:matlobgo/core/widgets/app_empty_state.dart';

import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';

import 'package:matlobgo/core/widgets/app_settings_banner.dart';

import 'package:matlobgo/models/app_settings.dart';

import 'package:matlobgo/models/order.dart';

import 'package:matlobgo/models/product.dart';

import 'package:matlobgo/models/store.dart';

import 'package:matlobgo/models/store_category_def.dart';

import 'package:matlobgo/screens/home/widgets/home_quick_filters.dart';

import 'package:matlobgo/screens/home/widgets/home_hero.dart';

import 'package:matlobgo/screens/home/widgets/matlob_home_feed.dart';

import 'package:matlobgo/screens/home/widgets/matlob_home_showcase_sections.dart';

import 'package:matlobgo/screens/home/widgets/matlob_home_ui_primitives.dart';

import 'package:matlobgo/services/promotion_service.dart';

import 'package:matlobgo/shared/home/home_catalog_sections.dart';

/// نصوص الصفحة الرئيسية — من CMS / قاعدة البيانات.

class MatlobHomeFeedCopy {
  const MatlobHomeFeedCopy({
    this.mostOrderedTitle = 'الأكثر طلباً',

    this.offersLabel = 'عروض',

    this.viewAllLabel = 'عرض الكل',

    this.trackOrderLabel = 'تفاصيل',

    this.freeDeliveryLabel = 'توصيل مجاني',
  });

  final String mostOrderedTitle;

  final String offersLabel;

  final String viewAllLabel;

  final String trackOrderLabel;

  final String freeDeliveryLabel;
}

const _homeSectionSpacer = SliverToBoxAdapter(
  child: SizedBox(height: HomeTheme.sectionGap),
);

/// MatlobGo mobile home feed — dynamic layout per category.

abstract final class MatlobHomePageSections {
  static const _sectionSpacer = _homeSectionSpacer;

  static List<Widget> buildSlivers({
    required List<PromoBanner> banners,

    required List<Store> featured,

    required List<Store> trending,

    required List<Store> stores,

    required List<Store> allStores,

    required List<StoreCategoryEntry> categories,

    required List<StoreCategoryDef> categoryDefinitions,

    required AppSettings settings,

    required String governorateName,

    String? selectedCategoryId,

    required HomeQuickFilter quickFilter,

    required void Function(HomeQuickFilter filter) onQuickFilterSelected,

    required void Function(StoreCategoryDef category) onCategoryTapped,

    required VoidCallback onSearchAll,

    required VoidCallback? onOffersTap,

    VoidCallback? onFilterTap,

    required void Function(Store store) onStoreTap,

    required void Function(Store store, Product product, List<Product> related)
    onProductTap,

    void Function(PromoBanner banner)? onBannerTap,

    Order? activeOrder,

    Store? activeOrderStore,

    VoidCallback? onTrackOrder,

    MatlobHomeFeedCopy copy = const MatlobHomeFeedCopy(),

    Widget? guestBanner,
  }) {
    String? selectedCategoryName;
    if (selectedCategoryId != null) {
      for (final d in categoryDefinitions) {
        if (d.id == selectedCategoryId) {
          selectedCategoryName = d.name;
          break;
        }
      }
    }

    final layout = MatlobHomeDynamicLayout.resolve(
      selectedCategoryName: selectedCategoryName,
      mostOrderedCms: copy.mostOrderedTitle,
    );

    final sectionKey = selectedCategoryId ?? 'all';

    final categoryScopedStores = StoreCatalogUtils.filterStores(
      allStores,
      categoryId: selectedCategoryId,
    );

    final mostOrdered = HomeCatalogSections.resolveMostOrdered(
      featured: featured,
      trending: trending,
      allStores: categoryScopedStores,
    );

    final offerStores = HomeCatalogSections.flashDealStores(
      categoryScopedStores,
      promotions: PromotionService.instance.promotions,
    );

    return [
      if (settings.maintenanceMode) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),

            child: AppSettingsBanner(settings: settings, maintenance: true),
          ),
        ),

        _sectionSpacer,
      ],

      if (settings.hasActiveAlertBanner) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),

            child: AppSettingsBanner(settings: settings, maintenance: false),
          ),
        ),

        _sectionSpacer,
      ],

      const SliverToBoxAdapter(
        child: SizedBox(height: MatlobHomeLayout.heroToContentGap),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTheme.pageHorizontal,
          ),

          child: MatlobPromoCarousel(
            key: ValueKey(banners.map((b) => b.id).join('|')),

            banners: banners,

            onBannerTap: onBannerTap,
          ),
        ),
      ),

      _sectionSpacer,

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTheme.pageHorizontal,
          ),

          child: MatlobSectionHeader(
            title: 'التصنيفات',

            actionLabel: copy.viewAllLabel,

            onAction: onSearchAll,
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 12)),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeTheme.pageHorizontal,
          ),

          child: MatlobCategoryCircleRow(
            categories: categories,
            offersLabel: copy.offersLabel,
            selectedCategoryId: selectedCategoryId,
            onOffersTap: onOffersTap,
            onCategoryTap: onCategoryTapped,
          ),
        ),
      ),

      if (selectedCategoryId == null && featured.isNotEmpty) ...[
        _sectionSpacer,

        SliverToBoxAdapter(
          child: MatlobFeaturedStoresSection(
            stores: featured,

            onStoreTap: onStoreTap,

            viewAllLabel: copy.viewAllLabel,

            onViewAll: onSearchAll,
          ),
        ),
      ],

      if (activeOrder != null && onTrackOrder != null) ...[
        _sectionSpacer,

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),

            child: MatlobSectionHeader(title: 'طلبك الحالي'),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeTheme.pageHorizontal,
            ),

            child: MatlobContinueOrderBanner(
              order: activeOrder,

              store: activeOrderStore,

              trackLabel: copy.trackOrderLabel,

              onTrack: onTrackOrder,
            ),
          ),
        ),
      ],

      if (layout.showContextHeader) ...[
        _sectionSpacer,

        SliverToBoxAdapter(
          child: MatlobAnimatedSection(
            sectionKey: sectionKey,

            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeTheme.pageHorizontal,
              ),

              child: MatlobCategoryContextHeader(
                title: layout.contextTitle,
                icon: Icons.category_rounded,
              ),
            ),
          ),
        ),
      ],

      if (layout.showOffers && offerStores.isNotEmpty) ...[
        _sectionSpacer,

        SliverToBoxAdapter(
          child: MatlobAnimatedSection(
            sectionKey: '${sectionKey}_offers',

            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: MatlobHomeColors.sectionWarmBg,
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: HomeTheme.sectionGap,
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HomeTheme.pageHorizontal,
                  ),

                  child: MatlobFlashDealsSection(
                    stores: offerStores,

                    promotions: PromotionService.instance.promotions,

                    title: layout.offersTitle,

                    showCountdown: false,

                    onStoreTap: onStoreTap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],

      if (layout.showMostOrdered && mostOrdered.isNotEmpty) ...[
        _sectionSpacer,

        SliverToBoxAdapter(
          child: MatlobAnimatedSection(
            sectionKey: '${sectionKey}_most',

            child: MatlobPopularProductsSection(
              key: ValueKey(
                'popular_${mostOrdered.map((s) => s.id).take(4).join('|')}',
              ),

              stores: mostOrdered,

              title: layout.mostOrderedTitle,

              onProductTap: onProductTap,
            ),
          ),
        ),

        // مسافة صغيرة بين كروت الأكثر طلباً وقسم كل المتاجر
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],

      SliverToBoxAdapter(
        child: MatlobAnimatedSection(
          sectionKey: '${sectionKey}_all',

          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: MatlobHomeColors.sectionWhiteBg,
            ),

            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: HomeTheme.sectionGap,
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeTheme.pageHorizontal,
                ),

                child: stores.isEmpty
                    ? AppEmptyState.preset(
                        AppEmptyKind.stores,

                        title: HomeCatalogSections.emptyStoresTitle(
                          governorateName: governorateName,
                          selectedCategoryId: selectedCategoryId,
                          selectedCategoryName: selectedCategoryName,
                          definitions: categoryDefinitions,
                        ),

                        subtitle: HomeCatalogSections.emptyStoresSubtitle(
                          selectedCategoryId: selectedCategoryId,
                          selectedCategoryName: selectedCategoryName,
                          definitions: categoryDefinitions,
                        ),

                        onAction: onSearchAll,
                      )
                    : MatlobAllStoresSection(
                        title: layout.allStoresTitle,

                        stores: stores,

                        onStoreTap: onStoreTap,

                        onFilterTap: onFilterTap,

                        sectionKey: sectionKey,
                      ),
              ),
            ),
          ),
        ),
      ),

      if (guestBanner != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),

            child: guestBanner,
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}

/// عروض البرق — يستمع للعروض داخلياً دون إعادة بناء الصفحة كاملة.

class MatlobFlashDealsSliver extends StatelessWidget {
  const MatlobFlashDealsSliver({
    super.key,

    required this.allStores,

    required this.onStoreTap,
  });

  final List<Store> allStores;

  final void Function(Store store) onStoreTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PromotionService.instance,

      builder: (context, _) {
        final promotions = PromotionService.instance.promotions;

        final flashDeals = HomeCatalogSections.flashDealStores(
          allStores,

          promotions: promotions,
        );

        if (flashDeals.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverMainAxisGroup(
          slivers: [
            _homeSectionSpacer,

            SliverToBoxAdapter(
              child: ColoredBox(
                color: MatlobHomeColors.flashDealsBg,

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HomeTheme.pageHorizontal,

                    20,

                    HomeTheme.pageHorizontal,

                    20,
                  ),

                  child: MatlobFlashDealsSection(
                    key: const ValueKey('matlob_flash_deals'),

                    stores: flashDeals,

                    promotions: promotions,

                    onStoreTap: onStoreTap,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
