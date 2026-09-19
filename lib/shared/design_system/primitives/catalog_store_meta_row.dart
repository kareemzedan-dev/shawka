import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/shared/design_system/primitives/catalog_delivery_badge.dart';
import 'package:matlobgo/shared/design_system/primitives/catalog_rating.dart';

/// Rating · delivery time · delivery fee — unified store meta strip.
class CatalogStoreMetaRow extends StatelessWidget {
  const CatalogStoreMetaRow({
    super.key,
    required this.store,
    this.palette,
    this.style = CatalogStoreMetaStyle.filled,
  });

  final Store store;
  final AppPalette? palette;
  final CatalogStoreMetaStyle style;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? context.palette;

    if (style == CatalogStoreMetaStyle.inline) {
      return Row(
        children: [
          CatalogRating(rating: store.rating, palette: p),
          const SizedBox(width: 10),
          Icon(Icons.schedule_rounded, size: 13, color: p.textSecondary),
          const SizedBox(width: 2),
          Text(
            '${store.deliveryMinutes} د',
            style: HomeTheme.storeMeta(p).copyWith(fontSize: 11),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: HomeTheme.borderSm,
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: CatalogMetaChip(
              icon: Icons.star_rounded,
              label: store.rating.toStringAsFixed(1),
              iconColor: AppColors.primary,
              textColor: p.textPrimary,
              emphasized: true,
              palette: p,
            ),
          ),
          _MetaDivider(color: p.border),
          Expanded(
            child: CatalogMetaChip(
              icon: Icons.two_wheeler_rounded,
              label: '${store.deliveryMinutes} د',
              iconColor: p.textSecondary,
              textColor: p.textPrimary,
              palette: p,
            ),
          ),
          _MetaDivider(color: p.border),
          Expanded(
            child: CatalogDeliveryBadge(
              deliveryFee: store.deliveryFee,
              compact: true,
              palette: p,
            ),
          ),
        ],
      ),
    );
  }
}

enum CatalogStoreMetaStyle { filled, inline }

class _MetaDivider extends StatelessWidget {
  const _MetaDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 14, color: color);
  }
}
