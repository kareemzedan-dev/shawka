import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/bottom_nav_config.dart';
import 'package:matlobgo/models/push_deep_link.dart';
import 'package:matlobgo/navigation/app_navigation_controller.dart';
import 'package:matlobgo/navigation/app_tab.dart';

void main() {
  late AppNavigationController nav;

  setUp(() {
    nav = AppNavigationController.instance;
    nav.debugSetNavConfig(const BottomNavConfig());
    nav.select(HomeTab.home, force: true);
  });

  test('parses tab deep link paths', () {
    expect(HomeTabX.tryParse('/tab/cart'), HomeTab.cart);
    expect(HomeTabX.tryParse('tab/favorites'), HomeTab.favorites);
    expect(HomeTabX.tryParse('tab/search'), HomeTab.favorites);
    expect(HomeTabX.tryParse('profile'), HomeTab.profile);
    expect(HomeTabX.tryParse('unknown'), isNull);
  });

  test('navigation controller opens push deep links for tabs', () {
    expect(
      nav.openPushDeepLink(const PushDeepLink(route: PushDeepLinkRoute.cart)),
      isTrue,
    );
    expect(nav.current, HomeTab.cart);
    expect(nav.isMounted(HomeTab.cart), isTrue);

    expect(
      nav.openPushDeepLink(const PushDeepLink(route: PushDeepLinkRoute.search)),
      isTrue,
    );
    expect(nav.current, HomeTab.favorites);

    expect(
      nav.openPushDeepLink(
        const PushDeepLink(route: PushDeepLinkRoute.favorites),
      ),
      isTrue,
    );
    expect(nav.current, HomeTab.favorites);

    expect(
      nav.openPushDeepLink(const PushDeepLink(route: PushDeepLinkRoute.profile)),
      isTrue,
    );
    expect(nav.current, HomeTab.profile);

    expect(nav.openPath('/tab/orders'), isTrue);
    expect(nav.current, HomeTab.orders);
  });

  test('core tabs stay available in visibleTabs', () {
    expect(
      nav.visibleTabs,
      containsAll([HomeTab.home, HomeTab.cart, HomeTab.orders, HomeTab.profile]),
    );
    expect(nav.visibleTabs, contains(HomeTab.favorites));
  });

  test('hiding favorites via CMS removes it from visible tabs', () {
    nav.debugSetNavConfig(
      BottomNavConfig(
        tabs: BottomNavConfig.defaults
            .map(
              (tab) => tab.id == 'favorites'
                  ? tab.copyWith(visible: false)
                  : tab,
            )
            .toList(),
      ),
    );
    expect(nav.visibleTabs.contains(HomeTab.favorites), isFalse);
    expect(nav.visibleTabs, contains(HomeTab.home));
  });
}
