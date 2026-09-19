import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/widgets/product_hero_actions.dart';
import 'package:matlobgo/screens/home/widgets/matlob_store_detail_ui.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

const _coverHeight = 248.0;
const _heroBlendBg = Color(0xFFF8FAFC);

/// Hero لصفحة المتجر على الويب — Parallax + دمج ناعم + لوجو المتجر.
class TarfaStoreHero extends StatelessWidget {
  const TarfaStoreHero({
    super.key,
    required this.store,
    required this.onBack,
    required this.onShare,
    this.scrollOffset = 0,
    this.coverHeight = _coverHeight,
  });

  final Store store;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final double scrollOffset;
  final double coverHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final safeTop = top > 0 ? top : ProductTokens.spaceLg;
    final height = safeTop + coverHeight;
    final hasImage = (store.displayHeroImageUrl?.trim().isNotEmpty ?? false) ||
        (store.displayCoverUrl?.trim().isNotEmpty ?? false);
    final hasLogo = (store.displayLogoUrl?.trim().isNotEmpty ?? false) ||
        (store.displayLogoThumbUrl?.trim().isNotEmpty ?? false);
    final parallax = (scrollOffset * 0.28).clamp(0.0, 48.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Transform.translate(
            offset: Offset(0, parallax),
            child: Transform.scale(
              scale: 1 + (parallax / height) * 0.08,
              alignment: Alignment.topCenter,
              child: hasImage
                  ? TarfaWebImage(
                      kind: TarfaImageKind.storeCover,
                      fill: true,
                      fit: BoxFit.cover,
                      imageUrl: store.displayHeroImageUrl ?? store.displayCoverUrl,
                      thumbnailUrl:
                          store.displayHeroThumbUrl ?? store.displayCoverThumbUrl,
                      useFullResolution: true,
                      fallback: const _HeroFallback(),
                    )
                  : const _HeroFallback(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0, 0.22, 0.48],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 128,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _heroBlendBg.withValues(alpha: 0.08),
                      _heroBlendBg.withValues(alpha: 0.22),
                      _heroBlendBg.withValues(alpha: 0.48),
                      _heroBlendBg.withValues(alpha: 0.78),
                      _heroBlendBg.withValues(alpha: 0.94),
                      _heroBlendBg,
                    ],
                    stops: const [0, 0.12, 0.28, 0.48, 0.68, 0.86, 1],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: safeTop + 6,
            start: matlobStoreSide,
            end: matlobStoreSide,
            child: Row(
              children: [
                ProductHeroCircleButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  semanticLabel: 'رجوع',
                  onTap: onBack,
                ),
                const Spacer(),
                ProductHeroCircleButton(
                  icon: Icons.share_rounded,
                  semanticLabel: 'مشاركة المتجر',
                  onTap: onShare,
                ),
              ],
            ),
          ),
          if (hasLogo)
            PositionedDirectional(
              start: matlobStoreSide,
              bottom: 20,
              child: _HeroLogoBadge(store: store),
            ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.accentMuted,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _HeroLogoBadge extends StatelessWidget {
  const _HeroLogoBadge({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 63,
      height: 63,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
        child: TarfaWebImage(
          kind: TarfaImageKind.storeLogo,
          fill: true,
          fit: BoxFit.contain,
          imageUrl: store.displayLogoUrl,
          thumbnailUrl: store.displayLogoThumbUrl,
          fallback: ColoredBox(
            color: const Color(0xFFF0F1F3),
            child: Icon(
              Icons.storefront_rounded,
              size: 24,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
