import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/shared/design_system/primitives/catalog_favorite_button.dart';

/// بطاقة متجر مطابقة لتصميم SSOT — صورة كبيرة + شارات + تقييم + توصيل.
class SearchStoreCard extends StatelessWidget {
  const SearchStoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.showPopularBadge = false,
  });

  final Store store;
  final VoidCallback onTap;
  final bool showPopularBadge;

  @override
  Widget build(BuildContext context) {
    final delivery = store.deliveryFee <= 0
        ? 'توصيل مجاني'
        : 'توصيل ${store.deliveryFee.toInt()} ج.م';
    final etaLow = (store.deliveryMinutes - 5).clamp(10, 120);
    final etaHigh = (store.deliveryMinutes + 5).clamp(etaLow + 5, 150);
    final timeLabel = '$etaLow-$etaHigh دقيقة';

    return Material(
      color: SearchTokens.cardBackground,
      borderRadius: BorderRadius.circular(SearchTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SearchTokens.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SearchTokens.cardRadius),
            boxShadow: SearchTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: SearchTokens.storeCardImageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(SearchTokens.cardRadius),
                      ),
                      child: CatalogNetworkImage(
                        imageUrl: store.displayHeroImageUrl,
                        thumbnailUrl: store.displayHeroThumbUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 640,
                        cacheHeight: 320,
                        fallback: SafeAssetImage(
                          asset: AppAssets.categoryFallback,
                          fallbackIcon: store.categoryIcon,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: CatalogFavoriteButton(targetId: store.id),
                    ),
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          if (showPopularBadge || store.isFeaturedNow)
                            _OverlayBadge(
                              icon: Icons.star_rounded,
                              label: 'الأكثر بحثاً',
                              fill: Colors.white,
                              foreground: SearchTokens.popularHot,
                            ),
                          if (store.deliveryMinutes <= 35)
                            const _OverlayBadge(
                              icon: Icons.bolt_rounded,
                              label: 'توصيل سريع',
                              fill: SearchTokens.accent,
                              foreground: Colors.white,
                            ),
                          if ((store.discountLabel ?? '').trim().isNotEmpty)
                            _OverlayBadge(
                              icon: Icons.local_offer_rounded,
                              label: store.discountLabel!.trim(),
                              fill: SearchTokens.accent,
                              foreground: Colors.white,
                            ),
                        ],
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 8,
                      start: 8,
                      child: _StatusBadge(isOpen: store.isOpen),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  store.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CartTypography.style(
                                    fontSize: SearchTokens.storeNameSize,
                                    fontWeight: FontWeight.w800,
                                    color: store.isOpen
                                        ? SearchTokens.textPrimary
                                        : SearchTokens.textMuted,
                                  ),
                                ),
                              ),
                              if (store.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: SearchTokens.verified,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (store.rating > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: SearchTokens.popularChipFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: SearchTokens.star,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  store.rating.toStringAsFixed(1),
                                  style: CartTypography.style(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: SearchTokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (store.categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        store.categoryLabel,
                        style: CartTypography.style(
                          fontSize: SearchTokens.captionSize,
                          fontWeight: FontWeight.w600,
                          color: SearchTokens.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: SearchTokens.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          timeLabel,
                          style: CartTypography.style(
                            fontSize: SearchTokens.metaSize,
                            fontWeight: FontWeight.w600,
                            color: SearchTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.delivery_dining_rounded,
                          size: 14,
                          color: SearchTokens.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            delivery,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: SearchTokens.metaSize,
                              fontWeight: FontWeight.w600,
                              color: SearchTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({
    required this.icon,
    required this.label,
    required this.fill,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: CartTypography.style(
              fontSize: SearchTokens.badgeSize,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color =
        isOpen ? SearchTokens.openBadge : SearchTokens.closedBadge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SearchTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'مفتوح' : 'مغلق حالياً',
            style: CartTypography.style(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
