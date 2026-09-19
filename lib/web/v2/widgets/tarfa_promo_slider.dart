import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

class TarfaPromoSlider extends StatefulWidget {
  const TarfaPromoSlider({super.key, required this.banners});

  final List<PromoBanner> banners;

  @override
  State<TarfaPromoSlider> createState() => _TarfaPromoSliderState();
}

class _TarfaPromoSliderState extends State<TarfaPromoSlider> {
  late final PageController _controller;
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(TarfaPromoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_current + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: TarfaTokens.animSlow,
        curve: TarfaTokens.curve,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _bannerHeight(double width) {
    // Stable promo aspect — 2.4:1 desktop, 16:9 mobile.
    if (width < TarfaTokens.mobileBreakpoint) {
      return (width / (16 / 9)).clamp(168.0, 210.0);
    }
    return (width / 2.4).clamp(200.0, 280.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < TarfaTokens.mobileBreakpoint;
    final height = _bannerHeight(
      width > TarfaTokens.maxWidth ? TarfaTokens.maxWidth : width,
    );

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _PromoCard(banner: banner, isMobile: isMobile);
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: TarfaTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: TarfaTokens.animFast,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? TarfaTokens.secondary : TarfaTokens.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _PromoCard extends StatefulWidget {
  const _PromoCard({required this.banner, required this.isMobile});

  final PromoBanner banner;
  final bool isMobile;

  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.banner.accentColor ?? TarfaTokens.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TarfaTokens.s4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.01 : 1,
          duration: TarfaTokens.animFast,
          curve: TarfaTokens.curve,
          child: AnimatedContainer(
            duration: TarfaTokens.animFast,
            decoration: BoxDecoration(
              borderRadius: TarfaTokens.borderRadiusLg,
              boxShadow: _hovered ? TarfaTokens.shadowLg : TarfaTokens.shadowMd,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.banner.imageUrl != null)
                  TarfaWebImage(
                    kind: TarfaImageKind.banner,
                    fill: true,
                    fit: BoxFit.cover,
                    imageUrl: widget.banner.imageUrl,
                    thumbnailUrl: widget.banner.imageThumbUrl,
                    useFullResolution: true,
                    fallback: _BannerFallback(
                      banner: widget.banner,
                      accent: accent,
                    ),
                  )
                else if (widget.banner.imageAsset.isNotEmpty)
                  SafeAssetImage(
                    asset: widget.banner.imageAsset,
                    fallbackIcon: Icons.local_offer_rounded,
                  )
                else
                  _BannerFallback(banner: widget.banner, accent: accent),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(
                    widget.isMobile ? TarfaTokens.s24 : TarfaTokens.s40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.banner.title,
                        style: TarfaTokens.headlineMedium(context).copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: TarfaTokens.s8),
                      Text(
                        widget.banner.subtitle,
                        style: TarfaTokens.bodyLarge(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: TarfaTokens.s16),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        child: Text(widget.banner.cta),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback({required this.banner, required this.accent});

  final PromoBanner banner;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (banner.imageAsset.isNotEmpty) {
      return SafeAssetImage(
        asset: banner.imageAsset,
        fallbackIcon: Icons.local_offer_rounded,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            TarfaTokens.primary,
            accent.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_offer_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
