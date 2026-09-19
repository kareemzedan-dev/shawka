import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/utils/catalog_image_cache.dart';
import 'package:matlobgo/core/utils/catalog_warmup_service.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/push_deep_link.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/screens/home/category_browse_screen.dart';
import 'package:matlobgo/screens/home/checkout/order_details_screen.dart';
import 'package:matlobgo/screens/auth/signup_screen.dart';
import 'package:matlobgo/screens/home/notifications_screen.dart';
import 'package:matlobgo/screens/home/search_screen.dart';
import 'package:matlobgo/screens/home/tabs/cart_tab.dart';
import 'package:matlobgo/screens/home/tabs/offers_tab.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_feed.dart';
import 'package:matlobgo/screens/home/tabs/favorites_tab.dart';
import 'package:matlobgo/screens/home/tabs/orders_tab.dart';
import 'package:matlobgo/screens/home/tabs/profile_tab.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_page_sections.dart';
import 'package:matlobgo/screens/home/widgets/home_hero.dart';
import 'package:matlobgo/navigation/app_badge_provider.dart';
import 'package:matlobgo/navigation/app_bottom_nav.dart';
import 'package:matlobgo/navigation/app_navigation_controller.dart';
import 'package:matlobgo/navigation/app_tab.dart';
import 'package:matlobgo/navigation/app_tab_shell.dart';
import 'package:matlobgo/screens/home/widgets/home_quick_filters.dart';
import 'package:matlobgo/screens/home/widgets/home_skeleton_loaders.dart';
import 'package:matlobgo/shared/home/home_catalog_sections.dart';
import 'package:matlobgo/screens/home/store_detail_screen.dart';
import 'package:matlobgo/screens/home/product_detail_screen.dart';
import 'package:matlobgo/screens/service_area/service_area_unsupported_screen.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/repositories/user_repository.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/favorites_service.dart';
import 'package:matlobgo/services/notification_service.dart';
import 'package:matlobgo/services/presence_service.dart';
import 'package:matlobgo/services/promotion_service.dart';
import 'package:matlobgo/services/push_deep_link_service.dart';
import 'package:matlobgo/services/push_notification_service.dart';
import 'package:matlobgo/services/service_area_service.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RestorationMixin {
  final _authService = AuthService();
  StreamSubscription<Object?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;
  final _cartService = CartService.instance;
  final _orderService = OrderService.instance;
  final _notificationService = NotificationService.instance;
  final _catalog = CatalogService();
  final _config = AppConfigService.instance;
  final _serviceArea = ServiceAreaService.instance;
  final _nav = AppNavigationController.instance;
  final _badges = AppBadgeProvider.instance;
  final RestorableInt _restorableTabIndex = RestorableInt(0);

  AppUser? _user;
  bool _isLoading = true;
  String? _selectedCategoryId;
  HomeQuickFilter _quickFilter = HomeQuickFilter.all;
  Governorate _governorate = EgyptGovernorates.defaultGovernorate;
  String _locationLabel = EgyptGovernorates.defaultGovernorate.name;
  String? _zoneId;
  String? _lastImagePrefetchKey;

  @override
  String? get restorationId => 'home_shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorableTabIndex, 'tab_index');
    if (initialRestore) {
      _nav.restoreFromIndex(_restorableTabIndex.value);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _badges.bind(
      cart: _cartService,
      orders: _orderService,
      notifications: _notificationService,
      config: _config,
    );
    _nav.bindConfig(_config);
    _nav.bindOnChanged(_onNavTabChanged);
    _governorate =
        _serviceArea.governorate ?? _serviceArea.browsingCatalogGovernorate;
    _locationLabel = _serviceArea.locationLabel;
    _zoneId = _serviceArea.matchedZone?.id;
    _serviceArea.addListener(_onServiceAreaChanged);
    _loadUser();
    _authSub = _authService.authStateChanges.listen((user) {
      unawaited(_userSub?.cancel());
      _userSub = null;
      if (user == null) {
        unawaited(_applyUser(null));
        return;
      }
      _userSub = UserRepository().watchUser(user.uid).listen((profile) {
        unawaited(_applyUser(profile));
      });
    });
    _orderService.addListener(_onOrdersChanged);
    _notificationService.addListener(_onNotificationsChanged);
    _config.addListener(_onConfigChanged);
    CmsTextService.instance.addListener(_onConfigChanged);
    PromotionService.instance.bindGovernorate(_governorate.name);
    unawaited(AnalyticsService.instance.appOpen());
    _startBackgroundLocationRefresh();
    PresenceService.instance.start();
    unawaited(
      AnalyticsService.instance.screenView(
        screen: 'tab_home',
        label: 'الرئيسية',
      ),
    );
    PushDeepLinkService.instance.bindHandler(_handlePushDeepLink);
    _applyHomeSystemChrome();
  }

  void _applyHomeSystemChrome() {
    SystemChrome.setSystemUIOverlayStyle(
      AppColors.homeOverlay(isDark: ThemeService.instance.isDark),
    );
  }

  void _startBackgroundLocationRefresh() {
    final area = ServiceAreaService.instance;
    if (!area.canEnterAppImmediately) return;
    unawaited(area.refreshLocationInBackground());
    final gov = area.governorate?.name ?? _governorate.name;
    unawaited(CatalogWarmupService.instance.warmForGovernorate(gov));
  }

  Future<void> _handlePushDeepLink(PushDeepLink link) async {
    if (!mounted) return;
    if (_nav.openPushDeepLink(link)) return;
    switch (link.route) {
      case PushDeepLinkRoute.store:
        if (link.id.isEmpty) return;
        final store = await _catalog.getStore(link.id);
        if (!mounted || store == null) return;
        _openStore(store);
      case PushDeepLinkRoute.order:
        if (link.id.isEmpty) return;
        final order = _orderService.getById(link.id);
        if (!mounted || order == null) return;
        openOrderDetailsScreen(context, order: order);
      case PushDeepLinkRoute.home:
      case PushDeepLinkRoute.none:
      case PushDeepLinkRoute.search:
      case PushDeepLinkRoute.cart:
      case PushDeepLinkRoute.orders:
      case PushDeepLinkRoute.profile:
      case PushDeepLinkRoute.promotions:
      case PushDeepLinkRoute.favorites:
        break;
    }
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    unawaited(_userSub?.cancel());
    unawaited(AnalyticsService.instance.endSession(reason: 'dispose'));
    PresenceService.instance.stop();
    WidgetsBinding.instance.removeObserver(this);
    _nav.bindOnChanged(null);
    _nav.unbindConfig();
    _badges.unbind();
    _orderService.removeListener(_onOrdersChanged);
    _notificationService.removeListener(_onNotificationsChanged);
    _config.removeListener(_onConfigChanged);
    CmsTextService.instance.removeListener(_onConfigChanged);
    _serviceArea.removeListener(_onServiceAreaChanged);
    super.dispose();
  }

  void _onServiceAreaChanged() {
    if (!mounted) return;
    // Geo لا يحظر التطبيق؛ isBlocked دائماً false لـ App Access.
    if (_serviceArea.isBlocked) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ServiceAreaUnsupportedScreen(
            onUnblocked: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ),
        (_) => false,
      );
      return;
    }
    final gov =
        _serviceArea.governorate ?? _serviceArea.browsingCatalogGovernorate;
    final zoneId = _serviceArea.isBrowsingFallback
        ? null
        : _serviceArea.matchedZone?.id;
    final label = _serviceArea.locationLabel;
    if (gov.id == _governorate.id &&
        zoneId == _zoneId &&
        label == _locationLabel) {
      return;
    }
    setState(() {
      _governorate = gov;
      _zoneId = zoneId;
      _locationLabel = label;
      _selectedCategoryId = null;
      _quickFilter = HomeQuickFilter.all;
      _lastImagePrefetchKey = null;
    });
    PromotionService.instance.bindGovernorate(gov.name);
    unawaited(CatalogWarmupService.instance.warmForGovernorate(gov.name));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotificationService.instance.touchActive());
      unawaited(PresenceService.instance.pulse());
      unawaited(AnalyticsService.instance.appOpen());
      unawaited(_serviceArea.refreshLocationInBackground());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(AnalyticsService.instance.endSession(reason: state.name));
    }
  }

  void _onConfigChanged() {
    unawaited(_enforceGuestAccessPolicy());
    _nav.reconcileVisibility();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _enforceGuestAccessPolicy() async {
    if (_config.settings.enableGuestCheckout) {
      _bindOrdersForUser(_user);
      return;
    }
    if (_user?.isGuest != true) return;

    await _authService.signOut();
    if (!mounted) return;
    setState(() => _user = null);
    _orderService.bindCustomer(null);
    showAuthMessage(context, 'تم إيقاف الدخول كضيف — سجّل دخولك للمتابعة');
  }

  void _onOrdersChanged() => setState(() {});
  void _onNotificationsChanged() => setState(() {});

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentAppUser();
    await _applyUser(user);
  }

  Future<void> _applyUser(AppUser? user) async {
    _bindOrdersForUser(user);
    _notificationService.bindUser(user?.uid);
    unawaited(
      FavoritesService.instance.bindUser(
        user?.isGuest == true ? null : user?.uid,
      ),
    );
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
    AnalyticsService.instance.bindUser(
      userId: user?.uid,
      userName: user?.name ?? 'ضيف',
    );
    await _enforceGuestAccessPolicy();
  }

  void _bindOrdersForUser(AppUser? user) {
    if (user == null) {
      _orderService.bindCustomer(null);
      return;
    }
    if (user.isGuest && !_config.settings.enableGuestCheckout) {
      _orderService.bindCustomer(null);
      return;
    }
    _orderService.bindCustomer(user.uid);
  }

  void _preloadHomeImages({
    required List<PromoBanner> banners,
    required List<StoreCategoryEntry> categories,
    required List<Store> stores,
  }) {
    final key =
        '${_governorate.id}|${banners.length}|${categories.length}|${stores.length}';
    if (_lastImagePrefetchKey == key) return;
    _lastImagePrefetchKey = key;

    final urls = CatalogImageCache.filterPrefetchable(
      CatalogWarmupService.urlsFromHomeContent(
        banners: banners,
        categories: categories,
        stores: stores,
      ).take(8),
    );
    if (urls.isEmpty) return;
    unawaited(CatalogImageCache.prefetch(urls));
  }

  void _onTabChanged(HomeTab tab) => _nav.select(tab);

  void _onNavTabChanged(HomeTab tab) {
    _restorableTabIndex.value = _nav.currentIndex;
    unawaited(PresenceService.instance.pulse());
    unawaited(
      AnalyticsService.instance.screenView(
        screen: tab.analyticsScreen,
        label: tab.defaultLabel,
      ),
    );
    if (mounted) setState(() {});
  }

  void _openOffers() {
    unawaited(
      AnalyticsService.instance.screenView(
        screen: 'tab_offers',
        label: 'العروض',
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OffersTab(
          governorateName: _governorate.name,
          cartService: _cartService,
          onExploreStores: _onTabChanged,
        ),
      ),
    );
  }

  void _openFilterSheet(List<StoreCategoryEntry> categories) {
    showMatlobHomeFilterSheet(
      context,
      selected: _quickFilter,
      onSelected: (filter) => _onQuickFilterSelected(filter, categories),
    );
  }

  void _openSearch() {
    unawaited(
      AnalyticsService.instance.screenView(screen: 'search', label: 'البحث'),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          governorate: _governorate.name,
          cartService: _cartService,
        ),
      ),
    );
  }

  void _openNotifications() {
    unawaited(
      AnalyticsService.instance.screenView(
        screen: 'notifications',
        label: 'الإشعارات',
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            NotificationsScreen(notificationService: _notificationService),
      ),
    );
  }

  void _openProduct(Store store, Product product, List<Product> related) {
    openProductDetail(
      context,
      store: store,
      product: product,
      relatedProducts: related,
      cartService: _cartService,
    );
  }

  void _openStore(Store store) {
    if (!store.isActive) return;
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.storeView,
        screen: 'store_detail',
        label: 'فتح متجر ${store.name}',
        storeId: store.id,
        storeName: store.name,
      ),
    );
    openStoreDetail(context, store: store, cartService: _cartService);
  }

  void _handleBannerTap(
    PromoBanner banner,
    List<Store> stores,
    List<StoreCategoryDef> categories,
  ) {
    final route = banner.deepLinkRoute.trim().toLowerCase();
    final id = banner.deepLinkId.trim();
    if (!banner.hasDeepLink || (route == 'home' && id.isEmpty)) {
      showAuthMessage(context, banner.cta);
      return;
    }

    switch (route) {
      case 'store':
        for (final store in stores) {
          if (store.id == id) {
            _openStore(store);
            return;
          }
        }
        return;
      case 'category':
        if (id.isNotEmpty) {
          final def = StoreCatalogUtils.byId(categories, id);
          if (def != null) {
            unawaited(
              CategoryBrowseScreen.open(
                context,
                governorate: _governorate.name,
                category: def,
                cartService: _cartService,
                catalogService: _catalog,
              ),
            );
          } else {
            setState(() {
              _selectedCategoryId = id;
              _quickFilter = HomeQuickFilter.all;
            });
          }
        }
        return;
      case 'offer':
        _openOffers();
        return;
      case 'search':
        _openSearch();
        return;
      case 'home':
        return;
      // Product navigation needs both a store and a loaded product record.
      // Unsupported/malformed routes intentionally no-op.
      default:
        return;
    }
  }

  void _onQuickFilterSelected(
    HomeQuickFilter filter,
    List<StoreCategoryEntry> categories,
  ) {
    setState(() {
      _quickFilter = filter;
      if (filter == HomeQuickFilter.all) {
        _selectedCategoryId = null;
      }
    });
  }

  void _onCategoryTapped(StoreCategoryDef def) {
    unawaited(
      CategoryBrowseScreen.open(
        context,
        governorate: _governorate.name,
        category: def,
        cartService: _cartService,
        catalogService: _catalog,
      ),
    );
  }

  bool _isHomeContentLoading({
    required AsyncSnapshot<List<PromoBanner>> bannerSnap,
    required AsyncSnapshot<List<StoreCategoryDef>> catSnap,
    required AsyncSnapshot<List<Store>> storeSnap,
  }) {
    return (bannerSnap.connectionState == ConnectionState.waiting &&
            !bannerSnap.hasData) ||
        (catSnap.connectionState == ConnectionState.waiting &&
            !catSnap.hasData) ||
        (storeSnap.connectionState == ConnectionState.waiting &&
            !storeSnap.hasData);
  }

  Widget _buildTabPages() {
    return AppTabShell(
      controller: _nav,
      pages: {
        HomeTab.home: _buildHomeTab(),
        HomeTab.favorites: FavoritesTab(
          governorateName: _governorate.name,
          cartService: _cartService,
          onExploreStores: _onTabChanged,
        ),
        HomeTab.orders: OrdersTab(
          orderService: _orderService,
          onNotifications: _openNotifications,
          onExploreStores: () => _onTabChanged(HomeTab.home),
        ),
        HomeTab.cart: CartTab(
          cartService: _cartService,
          user: _user,
          governorate: _governorate,
          onGoHome: () => _onTabChanged(HomeTab.home),
          onOrderPlaced: () => _onTabChanged(HomeTab.orders),
        ),
        HomeTab.profile: ProfileTab(
          user: _user,
          authService: _authService,
          notificationService: _notificationService,
          governorateName: _governorate.name,
          onTabChanged: _onTabChanged,
          onUserUpdated: _loadUser,
          onExploreStores: () => _onTabChanged(HomeTab.home),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark;
        _applyHomeSystemChrome();
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppColors.homeOverlay(isDark: isDark),
          child: Scaffold(
            backgroundColor: MatlobHomeColors.bodyBg,
            extendBody: false,
            resizeToAvoidBottomInset: false,
            body: _isLoading ? _buildHomeSkeletonTab() : _buildTabPages(),
            bottomNavigationBar: const AppBottomNav(),
          ),
        );
      },
    );
  }

  Widget _buildHomeSkeletonTab() {
    final heroExpanded = MatlobHomeLayout.heroExpandedHeight(context);
    final heroCollapsed = MatlobHomeLayout.heroCollapsedHeight(context);
    final cms = CmsTextService.instance;

    return ColoredBox(
      color: MatlobHomeColors.bodyBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: MatlobHomeHeroDelegate(
              expandedHeight: heroExpanded,
              collapsedHeight: heroCollapsed,
              governorate: _governorate,
              locationLabel: _locationLabel,
              isGuest: true,
              welcomeMessage: cms.welcomeMessage(
                isGuest: true,
                userName: 'ضيف',
              ),
              searchHint: cms.homeSearchHint(),
              onNotificationTap: _openNotifications,
              onSearchTap: _openSearch,
              onProfileTap: () => _onTabChanged(HomeTab.profile),
            ),
          ),
          ...HomeSkeletonSlivers.build(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final userName = _user?.name ?? 'ضيف';
    final isGuest = _user?.isGuest ?? true;
    final bottomPad = MatlobHomeLayout.scrollBottomInset(context);
    final heroExpanded = MatlobHomeLayout.heroExpandedHeight(context);
    final heroCollapsed = MatlobHomeLayout.heroCollapsedHeight(context);

    return ColoredBox(
      color: MatlobHomeColors.bodyBg,
      child: StreamBuilder<List<PromoBanner>>(
        stream: _config.watchPromoBanners(
          _governorate.name,
          activityTypeId: _user?.activityTypeId,
        ),
        builder: (context, bannerSnap) {
          return StreamBuilder<List<StoreCategoryDef>>(
            stream: _catalog.watchCategories(
              _governorate.name,
              activityTypeId: _user?.activityTypeId,
            ),
            builder: (context, catSnap) {
              return StreamBuilder<List<Store>>(
                stream: _catalog.watchStores(
                  governorate: _governorate.name,
                  activityTypeId: _user?.activityTypeId,
                ),
                builder: (context, snapshot) {
                  final allInGov = snapshot.data ?? [];
                  final categoryDefs = catSnap.data ?? [];
                  final banners = bannerSnap.data ?? [];
                  PromoBannerDebug.log(
                    'Home.read govId=${_governorate.id} '
                    'Requested Governorate: "${_governorate.name}" '
                    'activity=${_user?.activityTypeId} '
                    'state=${bannerSnap.connectionState} '
                    'hasError=${bannerSnap.hasError} '
                    'count=${banners.length}',
                  );
                  for (final b in banners) {
                    PromoBannerDebug.dumpDisplay(b);
                  }
                  if (bannerSnap.hasError) {
                    PromoBannerDebug.exception(bannerSnap.error!);
                  }
                  final categories = StoreCatalogUtils.categoryEntries(
                    allInGov,
                    categoryDefs,
                    activityTypeId: _user?.activityTypeId,
                  );

                  var stores = StoreCatalogUtils.filterStores(
                    allInGov,
                    categoryId: _selectedCategoryId,
                  );
                  stores = HomeCatalogSections.applyQuickFilter(
                    stores,
                    _quickFilter,
                  );
                  final featured = HomeCatalogSections.featured(allInGov);
                  final trending = HomeCatalogSections.trending(
                    allInGov,
                    featured,
                  );

                  final isLoading = _isHomeContentLoading(
                    bannerSnap: bannerSnap,
                    catSnap: catSnap,
                    storeSnap: snapshot,
                  );

                  if (!isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _preloadHomeImages(
                        banners: banners,
                        categories: categories,
                        stores: stores,
                      );
                    });
                  }

                  final activeOrder = _orderService.activeOrders.isNotEmpty
                      ? _orderService.activeOrders.first
                      : null;
                  Store? activeOrderStore;
                  if (activeOrder != null && activeOrder.storeId.isNotEmpty) {
                    for (final store in allInGov) {
                      if (store.id == activeOrder.storeId) {
                        activeOrderStore = store;
                        break;
                      }
                    }
                  }

                  final cms = CmsTextService.instance;
                  final welcomeMessage = cms.welcomeMessage(
                    isGuest: isGuest,
                    userName: userName,
                  );
                  final searchHint = cms.homeSearchHint();
                  final feedCopy = MatlobHomeFeedCopy(
                    mostOrderedTitle: cms.homeMostOrderedTitle(),
                    offersLabel: cms.homeOffersLabel(),
                    viewAllLabel: cms.homeViewAllLabel(),
                    trackOrderLabel: cms.homeTrackOrderLabel(),
                    freeDeliveryLabel: cms.homeFreeDeliveryLabel(),
                  );

                  return RefreshIndicator.adaptive(
                    color: AppColors.primary,
                    edgeOffset: heroExpanded,
                    onRefresh: () async {
                      await _serviceArea.refreshLocationInBackground();
                      if (mounted) setState(() {});
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: MatlobHomeHeroDelegate(
                            expandedHeight: heroExpanded,
                            collapsedHeight: heroCollapsed,
                            governorate: _governorate,
                            locationLabel: _locationLabel,
                            userName: userName,
                            isGuest: isGuest,
                            welcomeMessage: welcomeMessage,
                            searchHint: searchHint,
                            ordersCount: _orderService.orders.length,
                            onNotificationTap: _openNotifications,
                            onProfileTap: () => _onTabChanged(HomeTab.profile),
                            onSearchTap: _openSearch,
                            onFilterTap: () => _openFilterSheet(categories),
                            notificationCount: _notificationService.unreadCount,
                          ),
                        ),
                        ...(isLoading
                            ? HomeSkeletonSlivers.build()
                            : MatlobHomePageSections.buildSlivers(
                                banners: banners,
                                featured: featured,
                                trending: trending,
                                stores: stores,
                                allStores: allInGov,
                                categories: categories,
                                categoryDefinitions: categoryDefs,
                                settings: _config.settings,
                                governorateName: _governorate.name,
                                selectedCategoryId: _selectedCategoryId,
                                quickFilter: _quickFilter,
                                onQuickFilterSelected: (filter) =>
                                    _onQuickFilterSelected(filter, categories),
                                onCategoryTapped: _onCategoryTapped,
                                onSearchAll: _openSearch,
                                onOffersTap: _openOffers,
                                onFilterTap: () => _openFilterSheet(categories),
                                onStoreTap: _openStore,
                                onProductTap: _openProduct,
                                activeOrder: activeOrder,
                                activeOrderStore: activeOrderStore,
                                copy: feedCopy,
                                onTrackOrder: activeOrder == null
                                    ? null
                                    : () => openOrderDetailsScreen(
                                        context,
                                        order: activeOrder,
                                      ),
                                onBannerTap: (b) =>
                                    _handleBannerTap(b, allInGov, categoryDefs),
                                guestBanner: isGuest
                                    ? _GuestBanner(
                                        onSignUp: () {
                                          Navigator.of(context)
                                              .push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const SignUpScreen(),
                                                ),
                                              )
                                              .then((_) => _loadUser());
                                        },
                                      )
                                    : (_user?.isCustomerPendingApproval == true)
                                    ? const _PendingReviewBanner()
                                    : null,
                              )),
                        SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingReviewBanner extends StatelessWidget {
  const _PendingReviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 28, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حسابك قيد المراجعة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'تقدر تتصفح المنتجات — الطلب متاح بعد موافقة الإدارة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onSignUp});

  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أنشئ حسابك',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  'احفظ طلباتك واستمتع بعروض حصرية',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textOnPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignUp,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'سجّل الآن',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
