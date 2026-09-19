import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/widgets/governorate_picker.dart';
import 'package:matlobgo/screens/home/widgets/home_hero.dart';
import 'package:matlobgo/screens/home/widgets/home_quick_filters.dart';
import 'package:matlobgo/screens/home/widgets/home_skeleton_loaders.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/shared/home/home_catalog_sections.dart';
import 'package:matlobgo/shared/home/home_page_sections.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/home/home_page_layout.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_live_stats_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';

/// Web home — mirrors mobile [HomeScreen] tab structure and visual DNA.
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key, this.govId});

  final String? govId;

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final _catalog = CatalogService();
  final _config = AppConfigService.instance;

  String? _selectedCategoryId;
  HomeQuickFilter _quickFilter = HomeQuickFilter.all;

  @override
  void initState() {
    super.initState();
    _syncGovernorate();
    _config.addListener(_onSettings);
    WebSeoService.instance.apply(
      title:
          'اطلب من موردي المواد الغذائية — ${WebGovernorateService.instance.governorateName}',
      description:
          'اكتشف أفضل موردي المواد الغذائية في ${WebGovernorateService.instance.governorateName} — بيانات حية من ${AppBranding.shortName}.',
      canonicalPath: WebConstants.governoratePath(
        widget.govId ?? WebGovernorateService.instance.governorateId,
      ),
      jsonLd: {
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        'name': WebConstants.siteName,
        'url': WebConstants.canonicalOrigin,
        'inLanguage': 'ar-EG',
      },
    );
  }

  @override
  void dispose() {
    _config.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    WebLiveStats.instance.onSettingsUpdated();
    setState(() {});
  }

  @override
  void didUpdateWidget(WebHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.govId != widget.govId) _syncGovernorate();
  }

  Future<void> _syncGovernorate() async {
    final id = widget.govId;
    if (id != null) {
      await WebGovernorateService.instance.setGovernorateById(id);
    }
    final gov = WebGovernorateService.instance.governorateName;
    WebLiveStats.instance.bindGovernorate(gov);
    WebLiveStats.instance.onSettingsUpdated();
    if (mounted) setState(() {});
  }

  bool _isLoading({
    required AsyncSnapshot<List<PromoBanner>> banners,
    required AsyncSnapshot<List<StoreCategoryDef>> cats,
    required AsyncSnapshot<List<Store>> stores,
  }) {
    return (banners.connectionState == ConnectionState.waiting &&
            !banners.hasData) ||
        (cats.connectionState == ConnectionState.waiting && !cats.hasData) ||
        (stores.connectionState == ConnectionState.waiting && !stores.hasData);
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

  void _openSearch() {
    context.push(
      '${WebConstants.governoratePath(WebGovernorateService.instance.governorateId)}/search',
    );
  }

  void _openStore(Store store) {
    if (!store.isActive) return;
    WebConversionService.instance.recordStoreVisit(store.id);
    context.push(WebConstants.storePath(store.id));
  }

  void _onCategorySelected(
    String? id,
    List<StoreCategoryEntry> categories,
  ) {
    setState(() {
      _selectedCategoryId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WebGovernorateService.instance,
      builder: (context, _) {
        final governorate = WebGovernorateService.instance.governorate;
        final govName = governorate.name;
        return HomePageLayout(
          builder: (context, grid) {
            return ColoredBox(
              color: AppColors.navy,
              child: Column(
                children: [
                  HomeHero(
                    governorate: governorate,
                    isGuest: true,
                    userName: 'ضيف',
                    onLocationTap: _pickGovernorate,
                    onNotificationTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppBranding.notificationsInAppMessage,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onSearchTap: _openSearch,
                  ),
                  Expanded(
                    child: PremiumBackground.body(
                      context,
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(HomeTheme.radiusLg),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: StreamBuilder<List<PromoBanner>>(
                          stream: _config.watchPromoBanners(govName),
                          builder: (context, bannerSnap) {
                            return StreamBuilder<List<StoreCategoryDef>>(
                              stream: _catalog.watchCategories(govName),
                              builder: (context, catSnap) {
                                return StreamBuilder<List<Store>>(
                                  stream: _catalog.watchStores(
                                    governorate: govName,
                                  ),
                                  builder: (context, storeSnap) {
                                    final allInGov = storeSnap.data ?? [];
                                    final categoryDefs = catSnap.data ?? [];
                                    final banners = bannerSnap.data ?? [];
                                    final categories =
                                        StoreCatalogUtils.categoryEntries(
                                      allInGov,
                                      categoryDefs,
                                    );
                                    var stores = StoreCatalogUtils.filterStores(
                                      allInGov,
                                      categoryId: _selectedCategoryId,
                                    );
                                    stores = HomeCatalogSections.applyQuickFilter(
                                      stores,
                                      _quickFilter,
                                    );

                                    final featured =
                                        HomeCatalogSections.featured(allInGov);
                                    final trending = HomeCatalogSections.trending(
                                      allInGov,
                                      featured,
                                    );

                                    final isLoading = _isLoading(
                                      banners: bannerSnap,
                                      cats: catSnap,
                                      stores: storeSnap,
                                    );

                                    if (!isLoading) {
                                      WebLiveStats.instance.onStoresUpdated(
                                        allInGov,
                                      );
                                    }

                                    final storesTitle =
                                        HomeCatalogSections.categorySectionTitle(
                                      _selectedCategoryId,
                                      categories,
                                    );

                                    return CustomScrollView(
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      slivers: [
                                        const SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: HomeTheme.spaceMd,
                                          ),
                                        ),
                                        if (isLoading)
                                          ...HomeSkeletonSlivers.build()
                                        else
                                          ...HomePageSections.buildSlivers(
                                            banners: banners,
                                            featured: featured,
                                            trending: trending,
                                            stores: stores,
                                            categories: categories,
                                            settings: _config.settings,
                                            governorateName: govName,
                                            storesSectionTitle: storesTitle,
                                            selectedCategoryId:
                                                _selectedCategoryId,
                                            onCategorySelected: (id) =>
                                                _onCategorySelected(
                                                  id,
                                                  categories,
                                                ),
                                            onSearchAll: _openSearch,
                                            onStoreTap: _openStore,
                                            grid: grid,
                                          ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 80),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
