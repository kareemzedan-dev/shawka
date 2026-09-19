import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/product.dart';

/// List-row product card — store detail + web catalog.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    this.enabled = true,
    this.onTap,
    this.onAdd,
    this.heroTag,
    this.palette,
    this.imageSize = 72,
    this.compact = false,
  });

  final Product product;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final String? heroTag;
  final AppPalette? palette;
  final double imageSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? context.palette;
    final showAdd = product.isInStock && onAdd != null;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 14 : HomeTheme.radiusSm),
      child: SizedBox(
        width: imageSize,
        height: imageSize,
        child: CatalogNetworkImage(
          imageUrl: product.imageUrl,
          thumbnailUrl: product.imageThumbUrl,
          fit: BoxFit.cover,
          cacheWidth: (imageSize * 2).round(),
          cacheHeight: (imageSize * 2).round(),
          fallback: ColoredBox(
            color: p.surfaceMuted,
            child: Icon(
              Icons.storefront_rounded,
              color: p.textHint.withValues(alpha: 0.55),
              size: compact ? 24 : 28,
            ),
          ),
        ),
      ),
    );

    final wrappedImage = heroTag != null ? Hero(tag: heroTag!, child: image) : image;

    final content = Row(
      children: [
        wrappedImage,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.navy,
                      )
                    : HomeTheme.storeName(p).copyWith(fontSize: 15.5),
              ),
              if (product.description != null &&
                  product.description!.trim().isNotEmpty) ...[
                SizedBox(height: compact ? 0 : 3),
                Text(
                  product.description!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        )
                      : HomeTheme.storeMeta(p).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${product.price.toStringAsFixed(compact ? 0 : 0)} ج.م',
                    style: compact
                        ? GoogleFonts.cairo(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          )
                        : HomeTheme.storeName(p).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                  ),
                  if (!product.isInStock) ...[
                    const SizedBox(width: 8),
                    _OutOfStockChip(compact: compact),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (showAdd)
          IconButton(
            onPressed: onAdd,
            icon: Icon(
              Icons.add_circle_rounded,
              color: AppColors.primary,
              size: compact ? 32 : 34,
            ),
          ),
      ],
    );

    if (compact) {
      return Material(
        color: Colors.white,
        borderRadius: HomeTheme.borderMd,
        elevation: 0,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: HomeTheme.borderMd,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: HomeTheme.borderMd,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              boxShadow: HomeTheme.softShadowLight,
            ),
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: p.border),
        boxShadow: HomeTheme.softShadow(p),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: HomeTheme.borderSm,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _OutOfStockChip extends StatelessWidget {
  const _OutOfStockChip({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'غير متاح',
        style: GoogleFonts.cairo(
          fontSize: compact ? 10 : 11,
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
