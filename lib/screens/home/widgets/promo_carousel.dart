import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_image_placeholder.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner>? onBannerTap;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  static const _autoPlayInterval = Duration(seconds: 4);
  static const _resumeDelay = Duration(seconds: 5);
  static const _slideDuration = Duration(milliseconds: 480);

  late final PageController _controller;
  Timer? _autoPlayTimer;
  Timer? _resumeTimer;
  int _current = 0;
  bool _autoPlayPaused = false;
  bool _programmaticPageChange = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(PromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _current = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.length <= 1) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) => _advanceBanner());
  }

  void _advanceBanner() {
    if (!mounted || _autoPlayPaused || !_controller.hasClients) return;
    final next = (_current + 1) % widget.banners.length;
    _programmaticPageChange = true;
    _controller.animateToPage(
      next,
      duration: _slideDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  void _pauseAutoPlayFromUser() {
    _autoPlayPaused = true;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (mounted) _autoPlayPaused = false;
    });
  }

  void _onPageChanged(int index) {
    final wasProgrammatic = _programmaticPageChange;
    _programmaticPageChange = false;

    if (_current != index) {
      setState(() => _current = index);
    }

    if (!wasProgrammatic) {
      _pauseAutoPlayFromUser();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 158,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _pauseAutoPlayFromUser();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _PromoBannerCard(
                    key: ValueKey(banner.id),
                    banner: banner,
                    onTap: () => widget.onBannerTap?.call(banner),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          _PageIndicators(count: widget.banners.length, current: _current),
        ],
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = current == index;
        return AnimatedContainer(
          duration: HomeTheme.animNormal,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: active ? 12 : 4,
          height: 4,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : palette.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({
    super.key,
    required this.banner,
    this.onTap,
  });

  final PromoBanner banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: HomeTheme.borderLg,
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: ClipRRect(
        borderRadius: HomeTheme.borderLg,
        child: Material(
          color: palette.card,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.7),
                ),
              ),
              child: banner.hasNetworkImage
                  ? CatalogNetworkImage(
                      imageUrl: banner.imageUrl,
                      thumbnailUrl: banner.imageThumbUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 640,
                      cacheHeight: 300,
                      fallback: _AssetBannerFallback(banner: banner),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        SafeAssetImage(
                          asset: banner.imageAsset,
                          fallbackIcon: Icons.local_offer_rounded,
                        ),
                        ..._textOverlay(banner),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _textOverlay(PromoBanner banner) {
    return [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.navy.withValues(alpha: 0.82),
              AppColors.navy.withValues(alpha: 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'عرض حصري',
                style: GoogleFonts.cairo(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              banner.title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                height: 1.15,
              ),
            ),
            if (banner.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                banner.subtitle,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

class _AssetBannerFallback extends StatelessWidget {
  const _AssetBannerFallback({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final asset = banner.imageAsset.trim();
    if (asset.isNotEmpty) {
      return SafeAssetImage(
        asset: asset,
        fallbackIcon: Icons.local_offer_rounded,
      );
    }
    return const CatalogImagePlaceholder(
      icon: Icons.local_offer_rounded,
      compact: true,
    );
  }
}
