import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_cart_drawer_controller.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';

class TarfaBottomNav extends StatelessWidget {
  const TarfaBottomNav({
    super.key,
    required this.location,
    required this.govId,
  });

  final String location;
  final String govId;

  int _indexForLocation(String location) {
    if (location.contains('/profile')) return 4;
    if (TarfaCartDrawerController.instance.isOpen) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _indexForLocation(location);

    return Container(
      decoration: BoxDecoration(
        color: TarfaTokens.surface,
        boxShadow: [
          BoxShadow(
            color: TarfaTokens.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TarfaTokens.s8,
            vertical: TarfaTokens.s8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                selected: selected == 0,
                onTap: () => context.go(WebConstants.governoratePath(govId)),
              ),
              ListenableBuilder(
                listenable: WebCartService.instance,
                builder: (context, _) {
                  final count = WebCartService.instance.itemCount;
                  return _NavItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'السلة',
                    selected: selected == 1,
                    badge: count > 0 ? count : null,
                    onTap: TarfaCartDrawerController.instance.open,
                  );
                },
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'طلباتي',
                selected: selected == 2,
                onTap: () => showWebAppConversionModal(context),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'حسابي',
                selected: selected == 4,
                onTap: () => context.go(WebConstants.profilePath(govId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : TarfaTokens.textMuted;
    final labelColor = selected ? TarfaTokens.secondary : TarfaTokens.textMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: TarfaTokens.borderRadius,
          child: AnimatedContainer(
            duration: TarfaTokens.animFast,
            curve: TarfaTokens.curve,
            padding: const EdgeInsets.symmetric(vertical: TarfaTokens.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: TarfaTokens.animFast,
                  curve: TarfaTokens.curve,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? TarfaTokens.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Badge(
                      isLabelVisible: badge != null,
                      label: Text('$badge'),
                      backgroundColor: TarfaTokens.primary,
                      child: Icon(icon, color: color, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: TarfaTokens.s4),
                Text(
                  label,
                  style: TarfaTokens.labelMedium(context).copyWith(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
