import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/bottom_nav_config.dart';
import 'package:matlobgo/models/push_deep_link.dart';
import 'package:matlobgo/navigation/app_tab.dart';
import 'package:matlobgo/services/app_config_service.dart';

typedef AppTabChangedListener = void Function(HomeTab tab);

/// متحكّم تنقل موحّد للـ Shell — المصدر الوحيد لتبويب التطبيق الحالي.
class AppNavigationController extends ChangeNotifier {
  AppNavigationController._();
  static final AppNavigationController instance = AppNavigationController._();

  HomeTab _current = HomeTab.home;
  final Set<HomeTab> _mountedTabs = {HomeTab.home};
  AppTabChangedListener? _onChanged;
  AppConfigService? _config;
  BottomNavConfig _navConfig = const BottomNavConfig();

  HomeTab get current => _current;

  Set<HomeTab> get mountedTabs => Set.unmodifiable(_mountedTabs);

  bool isMounted(HomeTab tab) => _mountedTabs.contains(tab);

  void bindOnChanged(AppTabChangedListener? listener) {
    _onChanged = listener;
  }

  void bindConfig(AppConfigService config) {
    _config?.removeListener(_pullConfig);
    _config = config;
    _config!.addListener(_pullConfig);
    _pullConfig();
  }

  void unbindConfig() {
    _config?.removeListener(_pullConfig);
    _config = null;
  }

  @visibleForTesting
  void debugSetNavConfig(BottomNavConfig config) {
    _navConfig = config;
    reconcileVisibility();
    notifyListeners();
  }

  void _pullConfig() {
    _navConfig = _config?.settings.bottomNav ?? const BottomNavConfig();
    reconcileVisibility();
    notifyListeners();
  }

  List<HomeTab> get visibleTabs {
    final byId = {for (final tab in _navConfig.tabs) tab.id: tab};
    final ordered = [...BottomNavConfig.defaults]
      ..sort((a, b) {
        final left = byId[a.id]?.sortOrder ?? a.sortOrder;
        final right = byId[b.id]?.sortOrder ?? b.sortOrder;
        return left.compareTo(right);
      });

    final result = <HomeTab>[];
    for (final entry in ordered) {
      final tab = HomeTabX.tryParse(entry.id);
      if (tab == null) continue;
      final visible = tab.isCore
          ? true
          : (byId[entry.id]?.visible ?? entry.visible);
      if (visible) result.add(tab);
    }
    if (result.isEmpty) {
      return const [
        HomeTab.home,
        HomeTab.cart,
        HomeTab.orders,
        HomeTab.profile,
      ];
    }
    return result;
  }

  int indexOf(HomeTab tab) => visibleTabs.indexOf(tab);

  int get currentIndex {
    final index = indexOf(_current);
    return index < 0 ? 0 : index;
  }

  void select(HomeTab tab, {bool force = false}) {
    final tabs = visibleTabs;
    final target = tabs.contains(tab) ? tab : HomeTab.home;
    _mountedTabs.add(target);
    if (!force && _current == target) {
      notifyListeners();
      return;
    }
    _current = target;
    _onChanged?.call(target);
    notifyListeners();
  }

  void selectByIndex(int index) {
    final tabs = visibleTabs;
    if (index < 0 || index >= tabs.length) return;
    select(tabs[index]);
  }

  void restoreFromIndex(int index) {
    final tabs = visibleTabs;
    if (tabs.isEmpty) return;
    final safe = index.clamp(0, tabs.length - 1);
    _mountedTabs.add(tabs[safe]);
    _current = tabs[safe];
    notifyListeners();
  }

  /// Deep link من مسار نصي: `/tab/cart`, `tab/search`, `cart`.
  bool openPath(String? path) {
    final tab = HomeTabX.tryParse(path);
    if (tab == null) return false;
    select(tab);
    return true;
  }

  /// Deep link من إشعار Push.
  bool openPushDeepLink(PushDeepLink link) {
    final tab = switch (link.route) {
      PushDeepLinkRoute.home || PushDeepLinkRoute.none => HomeTab.home,
      PushDeepLinkRoute.orders => HomeTab.orders,
      PushDeepLinkRoute.cart => HomeTab.cart,
      PushDeepLinkRoute.search => HomeTab.favorites,
      PushDeepLinkRoute.profile => HomeTab.profile,
      PushDeepLinkRoute.promotions => HomeTab.home,
      PushDeepLinkRoute.favorites => HomeTab.favorites,
      PushDeepLinkRoute.store ||
      PushDeepLinkRoute.order => null,
    };
    if (tab == null) return false;
    select(tab);
    return true;
  }

  /// يضمن أن التبويب الحالي ما زال ظاهراً بعد تغيّر CMS.
  void reconcileVisibility() {
    if (visibleTabs.contains(_current)) return;
    select(HomeTab.home, force: true);
  }
}
