import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/favorites_service.dart';

/// Sizing for «الأكثر طلبًا» — one full vertical card + peek (RTL-safe).
abstract final class TrendingCardLayout {
  static const double cardHeight = 180;
  static const double listHeight = cardHeight;
  static const double itemSpacing = 12;

  /// Image area — ~17% shorter than prior 104px for better info balance.
  static const double imageHeight = 86;
  static const double widthFactor = 0.88;

  static double cardWidthFor(double viewportWidth) {
    final available = viewportWidth - HomeTheme.pageHorizontal;
    return (available * widthFactor).clamp(268.0, 340.0);
  }

  static List<BoxShadow> featuredShadow(AppPalette palette) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: (palette.isDark ? Colors.black : AppColors.navy).withValues(
        alpha: palette.isDark ? 0.16 : 0.03,
      ),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Featured vertical store card for the trending carousel.
class TrendingHorizontalStoreCard extends StatefulWidget {
  const TrendingHorizontalStoreCard({
    super.key,
    required this.store,
    required this.width,
    this.onTap,
  });

  final Store store;
  final double width;
  final VoidCallback? onTap;

  static String badgeLabel(Store store) {
    if (store.isFeatured) return '⭐ متجر مميز';
    return '🔥 الأكثر طلباً';
  }

  @override
  State<TrendingHorizontalStoreCard> createState() =>
      _TrendingHorizontalStoreCardState();
}

class _TrendingHorizontalStoreCardState
    extends State<TrendingHorizontalStoreCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final palette = context.palette;
    final deliveryLabel = store.deliveryFee == 0
        ? 'مجاني'
        : '${store.deliveryFee.toInt()} ج';

    return SizedBox(
      width: widget.width,
      height: TrendingCardLayout.cardHeight,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: HomeTheme.animPress,
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: HomeTheme.borderLg,
              color: palette.card,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              boxShadow: TrendingCardLayout.featuredShadow(palette),
            ),
            child: ClipRRect(
              borderRadius: HomeTheme.borderLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: TrendingCardLayout.imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CatalogNetworkImage(
                          imageUrl: store.displayHeroImageUrl,
                          thumbnailUrl: store.displayHeroThumbUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 520,
                          cacheHeight: 270,
                          fallback: SafeAssetImage(
                            asset: AppAssets.categoryFallback,
                            fallbackIcon: store.categoryIcon,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.navy.withValues(alpha: 0.08),
                                Colors.transparent,
                                AppColors.navy.withValues(alpha: 0.2),
                              ],
                              stops: const [0, 0.45, 1],
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: _FavoriteChip(storeId: store.id),
                        ),
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: _TrendingBadge(
                            label: TrendingHorizontalStoreCard.badgeLabel(
                              store,
                            ),
                          ),
                        ),
                        if (!store.isOpen)
                          ColoredBox(
                            color: AppColors.navy.withValues(alpha: 0.48),
                            child: const Center(
                              child: Text(
                                'مغلق حالياً',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeTheme.storeName(palette).copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              letterSpacing: -0.2,
                              color: store.isOpen
                                  ? palette.textPrimary
                                  : palette.textHint,
                            ),
                          ),
                          const Spacer(),
                          _UnifiedMetaRow(
                            palette: palette,
                            rating: store.rating > 0
                                ? store.rating.toStringAsFixed(1)
                                : (store.reviewCount > 0
                                      ? '${store.reviewCount}'
                                      : null),
                            deliveryMinutes: store.deliveryMinutes,
                            deliveryLabel: deliveryLabel,
                            isFreeDelivery: store.deliveryFee == 0,
                          ),
                        ],
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

class _TrendingBadge extends StatelessWidget {
  const _TrendingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HomeTheme.badgeLabel.copyWith(
            fontSize: 8.5,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// Single compact row: rating · delivery time · fee (Deliveroo / Talabat style).
class _UnifiedMetaRow extends StatelessWidget {
  const _UnifiedMetaRow({
    required this.palette,
    this.rating,
    required this.deliveryMinutes,
    required this.deliveryLabel,
    required this.isFreeDelivery,
  });

  final AppPalette palette;
  final String? rating;
  final int deliveryMinutes;
  final String deliveryLabel;
  final bool isFreeDelivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: HomeTheme.borderSm,
        border: Border.all(color: palette.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          if (rating != null) ...[
            Expanded(
              child: _MetaItem(
                palette: palette,
                icon: Icons.star_rounded,
                label: rating!,
                iconColor: AppColors.primary,
                textColor: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            _MetaDivider(color: palette.border),
          ],
          Expanded(
            child: _MetaItem(
              palette: palette,
              icon: Icons.schedule_rounded,
              label: '$deliveryMinutes د',
              iconColor: palette.textSecondary,
              textColor: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          _MetaDivider(color: palette.border),
          Expanded(
            child: _MetaItem(
              palette: palette,
              icon: Icons.local_shipping_outlined,
              label: deliveryLabel,
              iconColor: isFreeDelivery
                  ? AppColors.primary
                  : palette.textSecondary,
              textColor: isFreeDelivery
                  ? AppColors.primary
                  : palette.textPrimary,
              fontWeight: isFreeDelivery ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: color.withValues(alpha: 0.85),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.palette,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.fontWeight,
  });

  final AppPalette palette;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: HomeTheme.storeMeta(palette).copyWith(
              fontSize: 11,
              fontWeight: fontWeight,
              color: textColor,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final isFavorite = FavoritesService.instance.isFavorite(storeId);
        return GestureDetector(
          onTap: () => FavoritesService.instance.toggle(storeId),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 15,
              color: isFavorite ? AppColors.primary : AppColors.white,
            ),
          ),
        );
      },
    );
  }
}
