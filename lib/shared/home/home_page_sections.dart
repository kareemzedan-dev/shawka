import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/core/widgets/app_settings_banner.dart';
import 'package:matlobgo/core/widgets/staggered_fade_in.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/widgets/category_section.dart';
import 'package:matlobgo/screens/home/widgets/home_section_title.dart';
import 'package:matlobgo/screens/home/widgets/promo_carousel.dart';
import 'package:matlobgo/screens/home/widgets/store_card.dart';
import 'package:matlobgo/shared/home/home_page_grid_config.dart';
import 'package:matlobgo/shared/home/home_trending_section.dart';

/// Canonical home feed sections — extracted from mobile [HomeScreen].
abstract final class HomePageSections {
  static List<Widget> buildSlivers({
    required List<PromoBanner> banners,
    required List<Store> featured,
    required List<Store> trending,
    required List<Store> stores,
    required List<StoreCategoryEntry> categories,
    required AppSettings settings,
    required String governorateName,
    required String storesSectionTitle,
    required String? selectedCategoryId,
    required void Function(String? id) onCategorySelected,
    required VoidCallback onSearchAll,
    required void Function(Store store) onStoreTap,
    void Function(PromoBanner banner)? onBannerTap,
    Widget? guestBanner,
    HomePageGridConfig grid = HomePageGridConfig.mobile,
  }) {
    return [
      if (settings.maintenanceMode) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: AppSettingsBanner(settings: settings, maintenance: true),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: HomeTheme.blockGap)),
      ],
      if (settings.hasActiveAlertBanner) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: AppSettingsBanner(settings: settings, maintenance: false),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: HomeTheme.blockGap)),
      ],
      if (banners.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeTheme.pageHorizontal,
            ),
            child: PromoCarousel(
              banners: banners,
              onBannerTap: onBannerTap,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
      ],
      SliverToBoxAdapter(
        child: HomeSectionTitle(
          title: 'تصفّح حسب التصنيف',
          actionLabel: 'عرض الكل',
          onAction: onSearchAll,
          padding: const EdgeInsets.fromLTRB(
            HomeTheme.pageHorizontal,
            0,
            HomeTheme.pageHorizontal,
            HomeTheme.itemGap,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: CategorySection(
          categories: categories,
          selectedCategoryId: selectedCategoryId,
          onSelected: onCategorySelected,
        ),
      ),
      if (featured.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
        SliverToBoxAdapter(
          child: SectionTitle(
            title: '⭐ متاجر مميزة',
            actionLabel: 'عرض الكل',
            onAction: onSearchAll,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: HomeTheme.pageHorizontal,
              ),
              itemCount: featured.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return StaggeredFadeIn(
                  index: index,
                  duration: HomeTheme.animNormal,
                  child: SizedBox(
                    width: 248,
                    child: StoreCard(
                      store: featured[index],
                      variant: StoreCardVariant.featured,
                      onTap: () => onStoreTap(featured[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      if (trending.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(
          child: HomeTrendingSection(
            stores: trending,
            onStoreTap: onStoreTap,
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
      SliverToBoxAdapter(
        child: SectionTitle(
          title: storesSectionTitle,
          actionLabel: 'عرض الكل',
          onAction: onSearchAll,
        ),
      ),
      if (stores.isEmpty)
        SliverToBoxAdapter(
          child: AppEmptyState.preset(
            AppEmptyKind.stores,
            title: 'لا توجد متاجر في $governorateName',
            subtitle: storesSectionTitle == 'كل المتاجر'
                ? 'جرّب محافظة أخرى أو تصنيفاً مختلفاً — المتاجر تُضاف باستمرار'
                : 'لا توجد متاجر في «$storesSectionTitle» حالياً — جرّب تصنيفاً آخر',
            onAction: onSearchAll,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            HomeTheme.pageHorizontal,
            0,
            HomeTheme.pageHorizontal,
            24,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: grid.crossAxisCount,
              mainAxisSpacing: grid.mainAxisSpacing,
              crossAxisSpacing: grid.crossAxisSpacing,
              childAspectRatio: grid.childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => StaggeredFadeIn(
                index: index % 6,
                child: StoreCard(
                  store: stores[index],
                  onTap: () => onStoreTap(stores[index]),
                ),
              ),
              childCount: stores.length,
            ),
          ),
        ),
      if (guestBanner != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: guestBanner,
          ),
        ),
    ];
  }
}
