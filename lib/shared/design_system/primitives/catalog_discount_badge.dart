import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';

/// Cover / promo discount label on store images.
class CatalogDiscountBadge extends StatelessWidget {
  const CatalogDiscountBadge({
    super.key,
    required this.label,
    this.icon = Icons.local_offer_outlined,
    this.background = AppColors.primary,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final bool compact;

  /// Trending / featured badge on store cover.
  factory CatalogDiscountBadge.trending(String label) {
    return CatalogDiscountBadge(
      label: label,
      icon: Icons.local_fire_department_rounded,
      background: AppColors.primary,
    );
  }

  factory CatalogDiscountBadge.featured() {
    return const CatalogDiscountBadge(
      label: 'مميز',
      icon: Icons.star_rounded,
      background: Color(0xB30A0A0A),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? AppColors.white
        : AppColors.textOnPrimary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 7 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: HomeTheme.badgeLabel.copyWith(
              color: fg,
              fontSize: compact ? 9 : 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
