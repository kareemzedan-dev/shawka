import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/shared/design_system/primitives/catalog_discount_badge.dart';
import 'package:matlobgo/shared/design_system/primitives/catalog_favorite_button.dart';
import 'package:matlobgo/shared/design_system/primitives/catalog_store_meta_row.dart';

enum CatalogStoreCardVariant { grid, featured, trending, horizontal }

/// Unified store card — mobile grid + web hover in one widget.
class CatalogStoreCard extends StatefulWidget {
  const CatalogStoreCard({
    super.key,
    required this.store,
    this.onTap,
    this.variant = CatalogStoreCardVariant.grid,
    this.showFavorite = true,
    this.width,
  });

  final Store store;
  final VoidCallback? onTap;
  final CatalogStoreCardVariant variant;
  final bool showFavorite;
  final double? width;

  static String? trendingBadgeLabel(Store store) {
    if (store.rating >= 4.5) return '🔥 الأكثر طلباً';
    if (store.isFeatured) return '⭐ مميز';
    if (store.deliveryMinutes <= 30) return '🚀 سريع';
    return '🔥 الأكثر طلباً';
  }

  @override
  State<CatalogStoreCard> createState() => _CatalogStoreCardState();
}

class _CatalogStoreCardState extends State<CatalogStoreCard> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final palette = context.palette;
    final isFeatured = widget.variant == CatalogStoreCardVariant.featured;
    final isTrending = widget.variant == CatalogStoreCardVariant.trending;
    final isHorizontal = widget.variant == CatalogStoreCardVariant.horizontal;
    final enableHover = kIsWeb;

    final card = GestureDetector(
      onTapDown: !enableHover
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : (_hover && enableHover ? 1.02 : 1),
        duration: enableHover ? HomeTheme.animStandard : HomeTheme.animPress,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: HomeTheme.animStandard,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: HomeTheme.borderLg,
            boxShadow: _hover && enableHover
                ? HomeTheme.softShadowFloating
                : isTrending
                    ? HomeTheme.trendingCardGlow
                    : isFeatured
                        ? HomeTheme.featuredCardGlow
                        : HomeTheme.softShadow(palette),
            border: _hover && enableHover
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  )
                : isTrending
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : isFeatured
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          )
                        : Border.all(
                            color: palette.border.withValues(alpha: 0.6),
                          ),
          ),
          child: ClipRRect(
            borderRadius: HomeTheme.borderLg,
            child: Stack(
              children: [
                ColoredBox(
                  color: palette.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StoreCover(
                        store: store,
                        variant: widget.variant,
                        showFavorite: widget.showFavorite,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          HomeTheme.spaceMd - 1,
                          isTrending ? 10 : isFeatured ? 9 : 8,
                          HomeTheme.spaceMd - 1,
                          isTrending ? 11 : isFeatured ? 10 : 9,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: HomeTheme.storeName(palette).copyWith(
                                fontSize: isTrending
                                    ? 15.5
                                    : isFeatured
                                        ? 14.5
                                        : 13.5,
                                color: store.isOpen
                                    ? palette.textPrimary
                                    : palette.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(
                              height: isTrending
                                  ? 9
                                  : isFeatured
                                      ? 8
                                      : 7,
                            ),
                            CatalogStoreMetaRow(
                              store: store,
                              palette: palette,
                              style: isHorizontal && kIsWeb
                                  ? CatalogStoreMetaStyle.inline
                                  : CatalogStoreMetaStyle.filled,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTrending)
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    start: 0,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!enableHover) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Opacity(opacity: store.isOpen ? 1 : 0.55, child: card),
    );
  }
}

class _StoreCover extends StatelessWidget {
  const _StoreCover({
    required this.store,
    required this.variant,
    required this.showFavorite,
  });

  final Store store;
  final CatalogStoreCardVariant variant;
  final bool showFavorite;

  double? get _fixedHeight => switch (variant) {
        CatalogStoreCardVariant.featured => 130.0,
        CatalogStoreCardVariant.horizontal => 110.0,
        CatalogStoreCardVariant.grid => kIsWeb ? 118.0 : null,
        CatalogStoreCardVariant.trending => null,
      };

  @override
  Widget build(BuildContext context) {
    final isTrending = variant == CatalogStoreCardVariant.trending;
    final imageUrl = store.displayHeroImageUrl;
    final thumbUrl = store.displayHeroThumbUrl;

    Widget image = CatalogNetworkImage(
      imageUrl: imageUrl,
      thumbnailUrl: thumbUrl,
      fit: BoxFit.cover,
      cacheWidth: 480,
      cacheHeight: 270,
      fallback: SafeAssetImage(
        asset: AppAssets.categoryFallback,
        fallbackIcon: store.categoryIcon,
      ),
    );

    if (_fixedHeight != null) {
      image = SizedBox(height: _fixedHeight, child: image);
    } else {
      image = AspectRatio(aspectRatio: 16 / 9, child: image);
    }

    return Stack(
      children: [
        image,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.navy.withValues(alpha: isTrending ? 0.28 : 0.18),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 7,
          left: 7,
          right: 7,
          child: Row(
            children: [
              if (isTrending) ...[
                CatalogDiscountBadge.trending(
                  CatalogStoreCard.trendingBadgeLabel(store)!,
                ),
              ] else ...[
                if (store.isFeatured) ...[
                  CatalogDiscountBadge.featured(),
                  const SizedBox(width: 4),
                ],
                if (_popularLabel(store) != null) ...[
                  CatalogDiscountBadge(
                    label: _popularLabel(store)!,
                    icon: Icons.trending_up_rounded,
                    background: AppColors.navy.withValues(alpha: 0.7),
                  ),
                ],
              ],
              const Spacer(),
              if (!isTrending && store.discountLabel != null)
                CatalogDiscountBadge(label: store.discountLabel!),
            ],
          ),
        ),
        if (showFavorite)
          PositionedDirectional(
            top: 6,
            start: 6,
            child: CatalogFavoriteButton(targetId: store.id),
          ),
        if (!store.isOpen)
          Positioned.fill(
            child: Container(
              color: AppColors.navy.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: HomeTheme.borderSm,
                ),
                child: Text(
                  'مغلق حالياً',
                  style: HomeTheme.storeMeta(context.palette).copyWith(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _popularLabel(Store store) {
    for (final tag in store.tags) {
      if (tag.contains('طلب') || tag.contains('شائع') || tag.contains('مبيع')) {
        return tag.length > 12 ? '${tag.substring(0, 12)}…' : tag;
      }
    }
    return null;
  }
}

/// Loading placeholder for web store grids.
class CatalogStoreCardSkeleton extends StatelessWidget {
  const CatalogStoreCardSkeleton({super.key, this.width = 180});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 218,
      decoration: BoxDecoration(
        borderRadius: HomeTheme.borderLg,
        gradient: const LinearGradient(
          colors: [Color(0xFFE8ECF3), Color(0xFFF3F5FA), Color(0xFFE8ECF3)],
        ),
      ),
    );
  }
}
