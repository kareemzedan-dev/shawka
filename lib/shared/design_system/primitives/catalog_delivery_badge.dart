import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';

/// Delivery fee / time chip for store cards and meta rows.
class CatalogDeliveryBadge extends StatelessWidget {
  const CatalogDeliveryBadge({
    super.key,
    required this.deliveryFee,
    this.deliveryMinutes,
    this.compact = false,
    this.palette,
  });

  final double deliveryFee;
  final int? deliveryMinutes;
  final bool compact;
  final AppPalette? palette;

  String get _feeLabel =>
      deliveryFee == 0 ? 'توصيل مجاني' : 'توصيل ${deliveryFee.toInt()} ج.م';

  @override
  Widget build(BuildContext context) {
    final p = palette ?? context.palette;
    final isFree = deliveryFee == 0;

    if (compact && deliveryMinutes != null) {
      return CatalogMetaChip(
        icon: Icons.local_shipping_outlined,
        label: deliveryFee == 0 ? 'مجاني' : '${deliveryFee.toInt()} ج',
        iconColor: isFree ? AppColors.primary : p.textSecondary,
        textColor: isFree ? AppColors.primary : p.textPrimary,
        emphasized: isFree,
        palette: p,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.primary.withValues(alpha: 0.1)
            : p.surfaceMuted,
        borderRadius: HomeTheme.borderSm,
        border: Border.all(
          color: isFree
              ? AppColors.primary.withValues(alpha: 0.25)
              : p.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 13,
            color: isFree ? AppColors.primary : p.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            deliveryMinutes != null
                ? '$_feeLabel · $deliveryMinutes د'
                : _feeLabel,
            style: HomeTheme.badgeLabel.copyWith(
              fontSize: 10,
              color: isFree ? AppColors.primary : p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + label cell used inside meta rows.
class CatalogMetaChip extends StatelessWidget {
  const CatalogMetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.palette,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final AppPalette palette;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: HomeTheme.storeMeta(palette).copyWith(
              fontSize: 10.5,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
