import 'package:flutter/material.dart';
import 'package:matlobgo/navigation/app_navigation_controller.dart';
import 'package:matlobgo/navigation/app_tab.dart';
import 'package:matlobgo/screens/home/widgets/tab_activity_scope.dart';

/// يحافظ على حالة كل تبويب عبر [IndexedStack] مع تحميل كسول.
class AppTabShell extends StatelessWidget {
  const AppTabShell({
    super.key,
    required this.pages,
    this.controller,
  });

  final Map<HomeTab, Widget> pages;
  final AppNavigationController? controller;

  @override
  Widget build(BuildContext context) {
    final nav = controller ?? AppNavigationController.instance;
    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) {
        final tabs = nav.visibleTabs;
        final index = nav.currentIndex.clamp(0, tabs.length - 1);
        return IndexedStack(
          index: index,
          sizing: StackFit.expand,
          children: [
            for (final tab in tabs)
              _KeepAliveTab(
                key: PageStorageKey<String>('app_tab_${tab.name}'),
                isActive: nav.current == tab,
                isMounted: nav.isMounted(tab),
                child: pages[tab] ?? const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }
}

class _KeepAliveTab extends StatelessWidget {
  const _KeepAliveTab({
    super.key,
    required this.isActive,
    required this.isMounted,
    required this.child,
  });

  final bool isActive;
  final bool isMounted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isMounted) return const SizedBox.shrink();
    return TickerMode(
      enabled: isActive,
      child: Offstage(
        offstage: false,
        child: TabActivityScope(
          isActive: isActive,
          child: child,
        ),
      ),
    );
  }
}
