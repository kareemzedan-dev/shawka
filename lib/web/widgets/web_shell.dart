import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/widgets/web_conversion_banner.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';
import 'package:matlobgo/web/widgets/web_conversion_popup.dart';

class WebShell extends StatelessWidget {
  const WebShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(String location) {
    if (location.contains('/cart')) return 2;
    if (location.contains('/stores')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < WebConstants.mobileBreakpoint;
    final index = _selectedIndex(location);
    final showNav = !location.contains('/product/');

    return WebConversionPopupHost(
      child: Scaffold(
        backgroundColor: PremiumBackground.scaffoldColor(context),
        body: Stack(
          children: [
            Positioned.fill(
              child: PremiumBackgroundBackdrop(),
            ),
            Column(
              children: [
                if (!isMobile) const _WebTopBar(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: WebConstants.maxContentWidth,
                      ),
                      child: child,
                    ),
                  ),
                ),
                if (showNav && isMobile) ...[
                  const WebConversionBanner(),
                  _WebBottomNav(selectedIndex: index),
                ],
              ],
            ),
            if (!isMobile && showNav)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: WebConversionBanner(),
              ),
          ],
        ),
        floatingActionButton: showNav && !isMobile
            ? ListenableBuilder(
                listenable: WebCartService.instance,
                builder: (context, _) {
                  final count = WebCartService.instance.itemCount;
                  if (count == 0) return const SizedBox.shrink();
                  return FloatingActionButton.extended(
                    onPressed: () => context.go('/cart'),
                    backgroundColor: AppColors.primary,
                    icon: Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.shopping_bag_rounded),
                    ),
                    label: Text(
                      'السلة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}

class _WebTopBar extends StatelessWidget {
  const _WebTopBar();

  @override
  Widget build(BuildContext context) {
    final gov = GoRouterState.of(context).pathParameters['govId'] ?? 'cairo';
    return Material(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                WebConstants.siteName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(WebConstants.governoratePath(gov)),
                child: Text('الرئيسية', style: GoogleFonts.cairo(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => context.go(WebConstants.storesPath(gov)),
                child: Text('الموردون', style: GoogleFonts.cairo(color: Colors.white)),
              ),
              ListenableBuilder(
                listenable: WebCartService.instance,
                builder: (context, _) {
                  final count = WebCartService.instance.itemCount;
                  return TextButton.icon(
                    onPressed: () => context.go('/cart'),
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white),
                    ),
                    label: Text('السلة', style: GoogleFonts.cairo(color: Colors.white)),
                  );
                },
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => showWebAppConversionModal(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'حمّل التطبيق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebBottomNav extends StatelessWidget {
  const _WebBottomNav({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final gov = GoRouterState.of(context).pathParameters['govId'] ?? 'cairo';
    return NavigationBar(
      selectedIndex: selectedIndex,
      height: 64,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(WebConstants.governoratePath(gov));
          case 1:
            context.go(WebConstants.storesPath(gov));
          case 2:
            context.go('/cart');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront_rounded),
          label: 'الموردون',
        ),
        NavigationDestination(
          icon: ListenableBuilder(
            listenable: WebCartService.instance,
            builder: (context, _) {
              final count = WebCartService.instance.itemCount;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.shopping_bag_outlined),
              );
            },
          ),
          selectedIcon: const Icon(Icons.shopping_bag_rounded),
          label: 'السلة',
        ),
      ],
    );
  }
}
