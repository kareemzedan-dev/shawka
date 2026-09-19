import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';

/// Star rating display — single value or compact row.
class CatalogRating extends StatelessWidget {
  const CatalogRating({
    super.key,
    required this.rating,
    this.size = CatalogRatingSize.compact,
    this.showStarIcon = true,
    this.palette,
  });

  final double rating;
  final CatalogRatingSize size;
  final bool showStarIcon;
  final AppPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? context.palette;
    final iconSize = switch (size) {
      CatalogRatingSize.compact => 14.0,
      CatalogRatingSize.medium => 16.0,
      CatalogRatingSize.large => 18.0,
    };
    final fontSize = switch (size) {
      CatalogRatingSize.compact => 10.5,
      CatalogRatingSize.medium => 12.0,
      CatalogRatingSize.large => 14.0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStarIcon) ...[
          Icon(Icons.star_rounded, size: iconSize, color: AppColors.primary),
          const SizedBox(width: 3),
        ],
        Text(
          rating.toStringAsFixed(1),
          style: HomeTheme.storeMeta(p).copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }
}

enum CatalogRatingSize { compact, medium, large }
