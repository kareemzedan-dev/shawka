import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_typography.dart';
import 'package:matlobgo/navigation/app_badge_provider.dart';
import 'package:matlobgo/navigation/app_navigation_controller.dart';
import 'package:matlobgo/navigation/app_tab.dart';
import 'package:matlobgo/services/cms_text_service.dart';

/// شريط التنقل السفلي الموحّد — المكوّن الوحيد المسموح به للتطبيق.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    this.controller,
    this.badges,
  });

  final AppNavigationController? controller;
  final AppBadgeProvider? badges;

  static const _inactive = Color(0xFF9AA3AF);

  @override
  Widget build(BuildContext context) {
    final nav = controller ?? AppNavigationController.instance;
    final badgeProvider = badges ?? AppBadgeProvider.instance;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ListenableBuilder(
      listenable: Listenable.merge([nav, badgeProvider, CmsTextService.instance]),
      builder: (context, _) {
        final tabs = nav.visibleTabs;
        return Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.navy.withValues(alpha: 0.06),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset + 8),
              child: Row(
                children: [
                  for (final tab in tabs)
                    Expanded(
                      child: _NavTabButton(
                        tab: tab,
                        label: _labelFor(tab),
                        isActive: nav.current == tab,
                        badgeLabel: _badgeLabel(tab, badgeProvider),
                        badgeIsDot: () {
                          final kind = _badgeKind(tab);
                          if (kind == null) return false;
                          return badgeProvider.style == AppBadgeStyle.dot &&
                              badgeProvider.shouldShow(kind);
                        }(),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          nav.select(tab);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _labelFor(HomeTab tab) {
    final cms = CmsTextService.instance;
    return switch (tab) {
      HomeTab.home => cms.resolve(CmsKeys.navHome, fallback: tab.defaultLabel),
      HomeTab.favorites =>
        cms.resolve(CmsKeys.navFavorites, fallback: tab.defaultLabel),
      HomeTab.cart => cms.resolve(CmsKeys.navCart, fallback: tab.defaultLabel),
      HomeTab.orders =>
        cms.resolve(CmsKeys.navOrders, fallback: tab.defaultLabel),
      HomeTab.profile =>
        cms.resolve(CmsKeys.navProfile, fallback: tab.defaultLabel),
    };
  }

  AppBadgeKind? _badgeKind(HomeTab tab) => switch (tab) {
    HomeTab.cart => AppBadgeKind.cart,
    HomeTab.orders => AppBadgeKind.orders,
    _ => null,
  };

  String? _badgeLabel(HomeTab tab, AppBadgeProvider badges) {
    final kind = _badgeKind(tab);
    if (kind == null) return null;
    return badges.labelFor(kind);
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.tab,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeLabel,
    this.badgeIsDot = false,
  });

  final HomeTab tab;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badgeLabel;
  final bool badgeIsDot;

  IconData get _icon => switch (tab) {
    HomeTab.home => isActive ? Icons.home_rounded : Icons.home_outlined,
    HomeTab.favorites =>
      isActive ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
    HomeTab.cart =>
      isActive ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined,
    HomeTab.orders =>
      isActive ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
    HomeTab.profile =>
      isActive ? Icons.person_rounded : Icons.person_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppBottomNav._inactive;
    final showBadge = badgeLabel != null;

    return Semantics(
      button: true,
      selected: isActive,
      label: showBadge && badgeLabel!.isNotEmpty
          ? '$label، $badgeLabel إشعار'
          : label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          scale: isActive ? 1.08 : 1,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Icon(_icon, color: color, size: 24),
                        ),
                        if (showBadge)
                          Positioned(
                            top: -2,
                            left: -2,
                            child: _BadgeChip(
                              label: badgeLabel!,
                              isDot: badgeIsDot || badgeLabel!.isEmpty,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedOpacity(
                    opacity: isActive ? 1 : 0.85,
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeTypography.style(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.isDot});

  final String label;
  final bool isDot;

  @override
  Widget build(BuildContext context) {
    if (isDot) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: HomeTypography.style(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
