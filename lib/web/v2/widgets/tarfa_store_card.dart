import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_ui_service.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

class TarfaStoreCard extends StatefulWidget {
  const TarfaStoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.compact = false,
  });

  final Store store;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<TarfaStoreCard> createState() => _TarfaStoreCardState();
}

class _TarfaStoreCardState extends State<TarfaStoreCard> {
  bool _hovered = false;

  String get _reviewLabel {
    final base = (widget.store.rating * 87).round();
    return '+${base > 50 ? base : 50}';
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: TarfaTokens.animFast,
        curve: TarfaTokens.curve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: TarfaTokens.borderRadius,
            child: AnimatedContainer(
              duration: TarfaTokens.animFast,
              curve: TarfaTokens.curve,
              decoration: BoxDecoration(
                color: TarfaTokens.surface,
                borderRadius: TarfaTokens.borderRadius,
                boxShadow:
                    _hovered ? TarfaTokens.shadowHover : TarfaTokens.shadowSm,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      TarfaWebImage(
                        kind: TarfaImageKind.storeCover,
                        aspectRatio: widget.compact ? 16 / 9 : 16 / 10,
                        imageUrl: store.displayCoverUrl,
                        thumbnailUrl: store.displayCoverThumbUrl,
                        fallback: SafeAssetImage(
                          asset: AppAssets.categoryFallback,
                          fallbackIcon: store.categoryIcon,
                        ),
                      ),
                      if (!store.isOpen)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TarfaTokens.s16,
                                  vertical: TarfaTokens.s8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Text(
                                  'مغلق حالياً',
                                  style: TarfaTokens.labelLarge(context)
                                      .copyWith(color: TarfaTokens.error),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (store.isFeatured)
                        Positioned(
                          top: TarfaTokens.s12,
                          right: TarfaTokens.s12,
                          child: _Badge(
                            label: 'مميز',
                            color: TarfaTokens.secondary,
                          ),
                        ),
                      if (store.discountLabel != null &&
                          store.discountLabel!.isNotEmpty)
                        Positioned(
                          top: TarfaTokens.s12,
                          left: TarfaTokens.s12,
                          child: _Badge(
                            label: store.discountLabel!,
                            color: TarfaTokens.success,
                          ),
                        ),
                      Positioned(
                        bottom: TarfaTokens.s12,
                        right: TarfaTokens.s12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: TarfaTokens.shadowSm,
                              border: Border.all(color: TarfaTokens.divider),
                            ),
                            child: TarfaWebImage(
                              kind: TarfaImageKind.storeLogo,
                              width: 44,
                              height: 44,
                              imageUrl: store.displayLogoUrl,
                              thumbnailUrl: store.displayLogoThumbUrl,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: TarfaTokens.s12,
                        left: TarfaTokens.s12,
                        child: ListenableBuilder(
                          listenable: TarfaFavoritesService.instance,
                          builder: (context, _) {
                            final fav = TarfaFavoritesService.instance
                                .isFavorite(store.id);
                            return _FavoriteButton(
                              active: fav,
                              onTap: () => TarfaFavoritesService.instance
                                  .toggle(store.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(TarfaTokens.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: TarfaTokens.titleLarge(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: TarfaTokens.s8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 18,
                            ),
                            const SizedBox(width: TarfaTokens.s4),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: TarfaTokens.labelLarge(context),
                            ),
                            Text(
                              ' ($_reviewLabel)',
                              style: TarfaTokens.bodyMedium(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: TarfaTokens.s12),
                        Row(
                          children: [
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              label: '${store.deliveryMinutes} د',
                            ),
                            const SizedBox(width: TarfaTokens.s8),
                            Flexible(
                              child: _MetaChip(
                                icon: Icons.delivery_dining_rounded,
                                label: store.deliveryFee == 0
                                    ? 'توصيل مجاني'
                                    : '${store.deliveryFee.toStringAsFixed(0)} ج.م',
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
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TarfaTokens.s12,
        vertical: TarfaTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: TarfaTokens.shadowSm,
      ),
      child: Text(
        label,
        style: TarfaTokens.labelMedium(context).copyWith(color: Colors.white),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(TarfaTokens.s8),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: active ? TarfaTokens.error : TarfaTokens.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TarfaTokens.s8,
        vertical: TarfaTokens.s4,
      ),
      decoration: BoxDecoration(
        color: TarfaTokens.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TarfaTokens.textMuted),
          const SizedBox(width: TarfaTokens.s4),
          Flexible(
            child: Text(
              label,
              style: TarfaTokens.labelMedium(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
