import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/theme/home_typography.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/models/promotion.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/widgets/home_hero.dart';
import 'package:matlobgo/screens/home/widgets/home_quick_filters.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_ui_primitives.dart';
import 'package:matlobgo/screens/home/widgets/tab_activity_scope.dart';
import 'package:matlobgo/shared/home/home_catalog_sections.dart';

// ─── Promo carousel ──────────────────────────────────────────────────────────

class MatlobPromoCarousel extends StatefulWidget {
  const MatlobPromoCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  final List<PromoBanner> banners;
  final void Function(PromoBanner banner)? onBannerTap;

  @override
  State<MatlobPromoCarousel> createState() => _MatlobPromoCarouselState();
}

class _MatlobPromoCarouselState extends State<MatlobPromoCarousel> {
  /// نقطة بداية بعيدة تسمح بالتمرير اللانهائي في الاتجاهين.
  static const int _infiniteBase = 10000;
  static const Duration _autoScrollInterval = Duration(seconds: 5);
  static const Duration _resumeDelay = Duration(seconds: 3);

  late final PageController _controller;
  Timer? _timer;
  Timer? _resumeTimer;
  int _page = _infiniteBase;
  bool _touching = false;

  int get _realIndex =>
      widget.banners.isEmpty ? 0 : _page % widget.banners.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _infiniteBase);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoScroll();
  }

  @override
  void didUpdateWidget(covariant MatlobPromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _stopTimer();
    }
    _syncAutoScroll();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _syncAutoScroll() {
    final shouldRun =
        TabActivityScope.isActiveOf(context) &&
        widget.banners.length > 1 &&
        !_touching;
    if (shouldRun) {
      _timer ??= Timer.periodic(_autoScrollInterval, (_) {
        if (!mounted) return;
        if (!TabActivityScope.isActiveOf(context)) {
          _stopTimer();
          return;
        }
        _advancePage();
      });
    } else {
      _stopTimer();
    }
  }

  void _advancePage() {
    if (!mounted ||
        _touching ||
        !_controller.hasClients ||
        widget.banners.length <= 1) {
      return;
    }
    _controller
        .animateToPage(
          _page + 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        )
        .catchError((_) {});
  }

  void _onTouchStart() {
    _touching = true;
    _resumeTimer?.cancel();
    _stopTimer();
  }

  void _onTouchEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (!mounted) return;
      _touching = false;
      _syncAutoScroll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      PromoBannerDebug.log(
        'Home.widget MatlobPromoCarousel EMPTY → MatlobPromoPlaceholder',
      );
      return const MatlobPromoPlaceholder();
    }

    PromoBannerDebug.log(
      'Home.widget MatlobPromoCarousel showing ${widget.banners.length}: '
      '${widget.banners.map((b) => b.id).join(",")}',
    );

    final single = widget.banners.length == 1;

    return Listener(
      onPointerDown: (_) => _onTouchStart(),
      onPointerUp: (_) => _onTouchEnd(),
      onPointerCancel: (_) => _onTouchEnd(),
      child: RepaintBoundary(
        child: SizedBox(
          height: 152,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                // لانهائي دائماً — المؤشر يعتمد على الفهرس الحقيقي (modulo).
                itemCount: null,
                physics: single
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemBuilder: (context, i) {
                  final banner = widget.banners[i % widget.banners.length];
                  return _PromoSlide(
                    banner: banner,
                    onTap: widget.onBannerTap == null
                        ? null
                        : () => widget.onBannerTap!(banner),
                  );
                },
              ),
              if (!single)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.banners.length, (i) {
                      final active = i == _realIndex;
                      return AnimatedContainer(
                        duration: HomeTheme.animNormal,
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: active
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.45),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder احترافي عند غياب البانرات من قاعدة البيانات.
class MatlobPromoPlaceholder extends StatelessWidget {
  const MatlobPromoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, AppColors.inkElevated],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مطلوب Go',
                  style: HomeTypography.style(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'كل اللي محتاجه يوصلك لحد بابك',
                  style: HomeTypography.style(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.delivery_dining_rounded,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({required this.banner, this.onTap});

  final PromoBanner banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MatlobPressableScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeTheme.radiusLg),
            color: AppColors.navy,
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'matlob_home_banner_${banner.id}',
                child: _BannerImage(banner: banner),
              ),
              // Overlay كحلي (هوية MatlobGo) — الصورة عنصر مساعد لا مسيطر.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    stops: [0.0, 0.45, 1.0],
                    colors: [
                      Color(0xD90A0A0A),
                      Color(0x990A0A0A),
                      Color(0x4D0A0A0A),
                    ],
                  ),
                ),
              ),
              if (banner.subtitle.isNotEmpty)
                PositionedDirectional(
                  top: 14,
                  start: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      banner.subtitle,
                      style: HomeTypography.style(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              if (banner.title.isNotEmpty)
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  top: banner.subtitle.isNotEmpty ? 46 : 20,
                  child: Text(
                    banner.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: HomeTypography.style(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.2,
                      shadows: const [
                        Shadow(
                          color: Color(0x73000000),
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              if (banner.cta.isNotEmpty)
                PositionedDirectional(
                  bottom: 14,
                  end: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      banner.cta,
                      style: HomeTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    if (!banner.hasNetworkImage) {
      PromoBannerDebug.imageIssue(
        bannerId: banner.id,
        reason: 'imageUrl empty/null',
        url: banner.imageUrl,
      );
    } else {
      PromoBannerDebug.dumpDisplay(banner);
    }
    if (banner.hasNetworkImage) {
      return CatalogNetworkImage(
        imageUrl: banner.imageUrl,
        thumbnailUrl: banner.imageThumbUrl,
        fit: BoxFit.cover,
        cacheWidth: 720,
        cacheHeight: 352,
        debugTag: 'PromoBanner:${banner.id}',
        fallback: _PromoFallback(banner: banner),
      );
    }
    if (banner.imageAsset.isNotEmpty) {
      PromoBannerDebug.log(
        'Home.image ID: ${banner.id} using asset=${banner.imageAsset}',
      );
      return SafeAssetImage(
        asset: banner.imageAsset,
        fallbackIcon: Icons.delivery_dining_rounded,
      );
    }
    PromoBannerDebug.imageIssue(
      bannerId: banner.id,
      reason: 'imageUrl empty/null and no asset → fallback gradient',
      url: banner.imageUrl,
    );
    return _PromoFallback(banner: banner);
  }
}

class _PromoFallback extends StatelessWidget {
  const _PromoFallback({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.accentMuted, AppColors.surface],
        ),
      ),
      child: Icon(
        Icons.delivery_dining_rounded,
        size: 72,
        color: AppColors.primary.withValues(alpha: 0.85),
      ),
    );
  }
}

// ─── Circular category row ───────────────────────────────────────────────────

class MatlobCategoryCircleRow extends StatelessWidget {
  const MatlobCategoryCircleRow({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.onOffersTap,
    this.offersLabel = 'عروض',
    this.selectedCategoryId,
  });

  final List<StoreCategoryEntry> categories;
  final void Function(StoreCategoryDef category)? onCategoryTap;
  final VoidCallback? onOffersTap;
  final String offersLabel;
  final String? selectedCategoryId;

  void _handleTap(StoreCategoryDef def) {
    HapticFeedback.selectionClick();
    onCategoryTap?.call(def);
  }

  @override
  Widget build(BuildContext context) {
    final showOffers = onOffersTap != null;
    final count = categories.length + (showOffers ? 1 : 0);
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          if (showOffers && index == categories.length) {
            return SizedBox(
              width: 80,
              child: _CircleCategoryItem(
                label: offersLabel,
                icon: Icons.percent_rounded,
                isOffers: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onOffersTap?.call();
                },
              ),
            );
          }

          final entry = categories[index];
          final def = entry.definition;
          return SizedBox(
            width: 80,
            child: _CircleCategoryItem(
              label: def.name,
              icon: def.icon,
              imageUrl: def.imageUrl,
              imageThumbUrl: def.imageThumbUrl,
              imageAsset: def.imageAsset,
              isSelected: selectedCategoryId == def.id,
              onTap: () => _handleTap(def),
            ),
          );
        },
      ),
    );
  }
}

class _CircleCategoryItem extends StatelessWidget {
  const _CircleCategoryItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.imageUrl,
    this.imageThumbUrl,
    this.imageAsset,
    this.isSelected = false,
    this.isOffers = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? imageUrl;
  final String? imageThumbUrl;
  final String? imageAsset;
  final bool isSelected;
  final bool isOffers;

  static const double _outerSize = 64;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'تصنيف $label',
      child: MatlobPressableScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isOffers ? _offersCircle() : _imageCircle(),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: HomeTheme.animNormal,
              curve: Curves.easeOutCubic,
              style: HomeTypography.style(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.navy,
                height: 1.2,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageCircle() {
    return AnimatedContainer(
      duration: HomeTheme.animNormal,
      curve: Curves.easeOutCubic,
      width: _outerSize,
      height: _outerSize,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasImage
          ? CatalogNetworkImage(
              imageUrl: imageUrl,
              thumbnailUrl: imageThumbUrl,
              fit: BoxFit.cover,
              cacheWidth: 132,
              cacheHeight: 132,
              fallback: _iconFallback(),
            )
          : imageAsset != null && imageAsset!.isNotEmpty
          ? SafeAssetImage(asset: imageAsset!, fallbackIcon: icon)
          : _iconFallback(),
    );
  }

  /// دائرة «عروض» — ذهبية داخل هالة فاتحة متوافقة مع الهوية.
  Widget _offersCircle() {
    return Container(
      width: _outerSize,
      height: _outerSize,
      decoration: const BoxDecoration(
        color: MatlobHomeColors.offersHalo,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: _outerSize - 12,
        height: _outerSize - 12,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textOnPrimary, size: 22),
      ),
    );
  }

  bool get _hasImage =>
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (imageThumbUrl != null && imageThumbUrl!.trim().isNotEmpty);

  Widget _iconFallback() {
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(child: Icon(icon, color: AppColors.primary, size: 22)),
    );
  }
}

// ─── Category context header ─────────────────────────────────────────────────

class MatlobCategoryContextHeader extends StatelessWidget {
  const MatlobCategoryContextHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: HomeTypography.style(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

// ─── Flash deals ─────────────────────────────────────────────────────────────

class MatlobFlashDealsSection extends StatefulWidget {
  const MatlobFlashDealsSection({
    super.key,
    required this.stores,
    this.promotions = const [],
    this.onStoreTap,
    this.title = 'عروض البرق 🔥',
    this.showCountdown = true,
  });

  final List<Store> stores;
  final List<Promotion> promotions;
  final void Function(Store store)? onStoreTap;
  final String title;
  final bool showCountdown;

  @override
  State<MatlobFlashDealsSection> createState() =>
      _MatlobFlashDealsSectionState();
}

class _MatlobFlashDealsSectionState extends State<MatlobFlashDealsSection> {
  Timer? _timer;
  Duration _remaining = const Duration(hours: 1);
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _remaining = _initialCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCountdownTimer();
  }

  @override
  void didUpdateWidget(covariant MatlobFlashDealsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCountdownTimer();
  }

  void _syncCountdownTimer() {
    if (!TabActivityScope.isActiveOf(context)) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!TabActivityScope.isActiveOf(context)) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.isNegative) _remaining = const Duration(hours: 1);
      });
    });
  }

  Duration _initialCountdown() {
    final now = DateTime.now();
    return DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        ).difference(now).isNegative
        ? const Duration(hours: 23, minutes: 59, seconds: 12)
        : DateTime(now.year, now.month, now.day, 23, 59, 59).difference(now);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stores.isEmpty) return const SizedBox.shrink();

    final countdown = widget.showCountdown
        ? (
            h: _remaining.inHours.remainder(24).toString().padLeft(2, '0'),
            m: _remaining.inMinutes.remainder(60).toString().padLeft(2, '0'),
            s: _remaining.inSeconds.remainder(60).toString().padLeft(2, '0'),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: HomeTypography.style(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.showCountdown && countdown != null) ...[
              const Spacer(),
              _CountdownCircle(value: countdown.h),
              _CountdownSep(),
              _CountdownCircle(value: countdown.m),
              _CountdownSep(),
              _CountdownCircle(value: countdown.s),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final store = widget.stores[index];
              final selected = index == _selected;
              final dealLabel = HomeCatalogSections.flashDealLabel(
                store,
                promotions: widget.promotions,
              );
              return MatlobPressableScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = index);
                  widget.onStoreTap?.call(store);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: HomeTheme.softShadow(context.palette),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CatalogNetworkImage(
                        imageUrl:
                            store.displayLogoUrl ?? store.displayHeroImageUrl,
                        thumbnailUrl:
                            store.displayLogoThumbUrl ??
                            store.displayHeroThumbUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 128,
                        cacheHeight: 128,
                        fallback: SafeAssetImage(
                          asset: AppAssets.categoryFallback,
                          fallbackIcon: store.categoryIcon,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 72,
                      child: Text(
                        store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: HomeTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (dealLabel != null) ...[
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 72,
                        child: Text(
                          dealLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: HomeTypography.style(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  const _CountdownCircle({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MatlobHomeColors.navy,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Text(
        value,
        style: HomeTypography.style(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CountdownSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: HomeTypography.style(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Most ordered ────────────────────────────────────────────────────────────

abstract final class MatlobHomeCardMetrics {
  static const double trendingImageHeight = 104;
  static const double trendingListHeight = 184;
}

class MatlobMostOrderedSection extends StatelessWidget {
  const MatlobMostOrderedSection({
    super.key,
    required this.stores,
    required this.onStoreTap,
    this.title = 'الأكثر طلباً',
    this.viewAllLabel = 'عرض الكل',
    this.freeDeliveryLabel = 'توصيل مجاني',
    this.onViewAll,
  });

  final List<Store> stores;
  final void Function(Store store) onStoreTap;
  final String title;
  final String viewAllLabel;
  final String freeDeliveryLabel;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();

    final cardWidth = (MediaQuery.sizeOf(context).width * 0.72).clamp(
      240.0,
      300.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MatlobSectionHeader(
          title: title,
          actionLabel: viewAllLabel,
          onAction: onViewAll,
          accented: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MatlobHomeCardMetrics.trendingListHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return MatlobFadeIn(
                delay: Duration(milliseconds: 40 * index.clamp(0, 5)),
                child: MatlobTrendingOrderCard(
                  store: store,
                  width: cardWidth,
                  freeDeliveryLabel: freeDeliveryLabel,
                  onTap: () => onStoreTap(store),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MatlobTrendingOrderCard extends StatelessWidget {
  const MatlobTrendingOrderCard({
    super.key,
    required this.store,
    required this.width,
    this.freeDeliveryLabel = 'توصيل مجاني',
    this.onTap,
  });

  final Store store;
  final double width;
  final String freeDeliveryLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final minTime = store.deliveryMinutes;
    final maxTime = store.deliveryMinutes + 10;
    final isFree = store.deliveryFee == 0;

    return SizedBox(
      width: width,
      child: MatlobPressableScale(
        onTap: onTap,
        enabled: true,
        child: Material(
          color: palette.card,
          borderRadius: HomeTheme.borderMd,
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: MatlobHomeCardStyle.decoration(
              background: palette.card,
              borderRadius: HomeTheme.borderMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: MatlobHomeCardMetrics.trendingImageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CatalogNetworkImage(
                        imageUrl: store.displayHeroImageUrl,
                        thumbnailUrl: store.displayHeroThumbUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        cacheHeight: 260,
                        fallback: SafeAssetImage(
                          asset: AppAssets.categoryFallback,
                          fallbackIcon: store.categoryIcon,
                        ),
                      ),
                      PositionedDirectional(
                        top: 10,
                        end: 10,
                        child: MatlobRatingBadge(
                          rating: store.rating,
                          compact: true,
                        ),
                      ),
                      if (!store.isOpen)
                        ColoredBox(
                          color: AppColors.navy.withValues(alpha: 0.45),
                          child: Center(
                            child: Text(
                              'مغلق حالياً',
                              style: HomeTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          MatlobDeliveryCapsule(
                            minMinutes: minTime,
                            maxMinutes: maxTime,
                          ),
                          const Spacer(),
                          MatlobPriceLabel(
                            amount: store.deliveryFee,
                            isFree: isFree,
                            freeLabel: freeDeliveryLabel,
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
    );
  }
}

// ─── All stores ──────────────────────────────────────────────────────────────

class MatlobAllStoresSection extends StatelessWidget {
  const MatlobAllStoresSection({
    super.key,
    required this.stores,
    required this.onStoreTap,
    this.title = 'كل المتاجر',
    this.onFilterTap,
    this.sectionKey = 'all',
  });

  final List<Store> stores;
  final void Function(Store store) onStoreTap;
  final String title;
  final VoidCallback? onFilterTap;
  final String sectionKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeTypography.style(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            if (onFilterTap != null)
              IconButton(
                onPressed: onFilterTap,
                icon: const Icon(Icons.tune_rounded, size: 20),
                color: AppColors.textHint,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...stores.asMap().entries.map(
          (entry) => MatlobFadeIn(
            key: ValueKey('$sectionKey-${entry.value.id}'),
            delay: Duration(milliseconds: 35 * entry.key.clamp(0, 8)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatlobStoreListTile(
                store: entry.value,
                onTap: () => onStoreTap(entry.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MatlobStoreListTile extends StatelessWidget {
  const MatlobStoreListTile({super.key, required this.store, this.onTap});

  final Store store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final categories = store.tags.isNotEmpty
        ? store.tags.take(3).join('، ')
        : store.categorySubtitle;
    final pills = store.tags.isNotEmpty
        ? store.tags.take(2).toList()
        : <String>[
            if (store.deliveryMinutes <= 30) 'سريع',
            if (store.rating >= 4.5) 'ممتاز',
          ];
    return MatlobPressableScale(
      onTap: onTap,
      enabled: true,
      child: Material(
        color: AppColors.white,
        borderRadius: HomeTheme.borderMd,
        elevation: 0,
        child: Container(
          decoration: MatlobHomeCardStyle.decoration(
            background: AppColors.white,
            borderRadius: HomeTheme.borderMd,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeTypography.style(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (!store.isOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'مغلق حالياً',
                              style: HomeTypography.style(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    if (pills.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final pill in pills)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  HomeTheme.radiusSm,
                                ),
                              ),
                              child: Text(
                                pill,
                                style: HomeTypography.style(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    MatlobStoreMetaRow(store: store),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(HomeTheme.radiusMd),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CatalogNetworkImage(
                    imageUrl: store.displayHeroImageUrl,
                    thumbnailUrl: store.displayHeroThumbUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 144,
                    cacheHeight: 144,
                    fallback: SafeAssetImage(
                      asset: AppAssets.categoryFallback,
                      fallbackIcon: store.categoryIcon,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class MatlobSectionHeader extends StatelessWidget {
  const MatlobSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.accented = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    final displayTitle = accented && !title.contains('🔥')
        ? '$title 🔥'
        : title;

    return Row(
      children: [
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTypography.style(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        if (onAction != null && actionLabel != null)
          Semantics(
            button: true,
            label: '$actionLabel — $title',
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                minimumSize: const Size(44, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: HomeTypography.style(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Filter sheet for extended quick filters.
Future<void> showMatlobHomeFilterSheet(
  BuildContext context, {
  required HomeQuickFilter selected,
  required ValueChanged<HomeQuickFilter> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final palette = ctx.palette;
      return Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تصفية المتاجر',
                style: HomeTypography.style(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HomeQuickFilter.values.map((filter) {
                  final isSelected = selected == filter;
                  return FilterChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (_) {
                      if (filter == HomeQuickFilter.all) {
                        onSelected(HomeQuickFilter.all);
                      } else {
                        onSelected(isSelected ? HomeQuickFilter.all : filter);
                      }
                      Navigator.pop(ctx);
                    },
                    selectedColor: AppColors.accentMuted,
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
