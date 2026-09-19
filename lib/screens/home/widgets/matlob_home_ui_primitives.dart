import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/theme/home_typography.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';

/// Shared card chrome — subtle border instead of heavy shadow.
abstract final class MatlobHomeCardStyle {
  static const Color borderColor = Color(0xFFEDEDED);

  static BoxDecoration decoration({
    required Color background,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: borderRadius ?? HomeTheme.borderMd,
      border: Border.all(color: borderColor),
    );
  }
}

/// Fade-in for cards and sections.
class MatlobFadeIn extends StatefulWidget {
  const MatlobFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<MatlobFadeIn> createState() => _MatlobFadeInState();
}

class _MatlobFadeInState extends State<MatlobFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Cross-fade when home sections change per category.
class MatlobAnimatedSection extends StatelessWidget {
  const MatlobAnimatedSection({
    super.key,
    required this.sectionKey,
    required this.child,
  });

  final String sectionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<String>(sectionKey), child: child),
    );
  }
}

/// Scale 0.97 on press — 120ms, gives cards a lively feel.
class MatlobPressableScale extends StatefulWidget {
  const MatlobPressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<MatlobPressableScale> createState() => _MatlobPressableScaleState();
}

class _MatlobPressableScaleState extends State<MatlobPressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canPress = widget.enabled && widget.onTap != null;

    return GestureDetector(
      onTapDown: canPress ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canPress ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: canPress ? () => setState(() => _pressed = false) : null,
      onTap: canPress ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: HomeTheme.animPress,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// White rating badge with shadow (Uber Eats style).
class MatlobRatingBadge extends StatelessWidget {
  const MatlobRatingBadge({
    super.key,
    required this.rating,
    this.compact = false,
  });

  final double rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(HomeTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐', style: TextStyle(fontSize: compact ? 11 : 13)),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: HomeTypography.style(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// صفّ معلومات المتجر — ⭐ التقييم · 🚴 رسوم التوصيل · 🕒 مدة التوصيل.
/// صف واحد بمحاذاة متساوية (نمط Uber Eats/Talabat).
class MatlobStoreMetaRow extends StatelessWidget {
  const MatlobStoreMetaRow({super.key, required this.store});

  final Store store;

  String? get _ratingLabel {
    if (store.rating <= 0 && store.reviewCount <= 0) return null;
    if (store.reviewCount <= 0) return store.rating.toStringAsFixed(1);
    if (store.rating <= 0) return '${store.reviewCount} تقييم';
    return '${store.rating.toStringAsFixed(1)} (${store.reviewCount})';
  }

  @override
  Widget build(BuildContext context) {
    final ratingLabel = _ratingLabel;
    final metaStyle = HomeTypography.style(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.2,
    );

    return Row(
      children: [
        if (ratingLabel != null) ...[
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
          const SizedBox(width: 3),
          Text(
            ratingLabel,
            style: HomeTypography.style(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              height: 1.2,
            ),
          ),
          const MatlobMetaDot(),
        ],
        Icon(
          Icons.delivery_dining_rounded,
          size: 15,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            store.deliveryFee == 0 ? 'مجاني' : '${store.deliveryFee.toInt()} ج',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metaStyle,
          ),
        ),
        const MatlobMetaDot(),
        Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '${store.deliveryMinutes} دقيقة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metaStyle,
          ),
        ),
      ],
    );
  }
}

/// نقطة فاصلة صغيرة بين عناصر صف المعلومات.
class MatlobMetaDot extends StatelessWidget {
  const MatlobMetaDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Container(
        width: 3.5,
        height: 3.5,
        decoration: const BoxDecoration(
          color: Color(0xFFD3D8DF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 🕒 30-40 دقيقة — light gray capsule.
class MatlobDeliveryCapsule extends StatelessWidget {
  const MatlobDeliveryCapsule({
    super.key,
    required this.minMinutes,
    required this.maxMinutes,
  });

  final int minMinutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(HomeTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 12,
            color: AppColors.navy.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 4),
          Text(
            '$minMinutes-$maxMinutes دقيقة',
            style: HomeTypography.style(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.navy.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bold delivery fee label — e.g. 🛵 15 ج.م
class MatlobPriceLabel extends StatelessWidget {
  const MatlobPriceLabel({
    super.key,
    required this.amount,
    this.isFree = false,
    this.freeLabel = 'توصيل مجاني',
    this.showIcon = true,
  });

  final double amount;
  final bool isFree;
  final String freeLabel;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final label = isFree ? freeLabel : '${amount.toInt()} ج';
    final color = AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.delivery_dining_rounded,
            size: 16,
            color: color.withValues(alpha: isFree ? 1 : 0.85),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: HomeTypography.style(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Active order banner — Continue Order.
class MatlobContinueOrderBanner extends StatelessWidget {
  const MatlobContinueOrderBanner({
    super.key,
    required this.order,
    required this.onTrack,
    this.store,
    this.trackLabel = 'تتبع',
  });

  final Order order;
  final VoidCallback onTrack;
  final Store? store;
  final String trackLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return MatlobPressableScale(
      onTap: onTrack,
      child: Material(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: MatlobHomeCardStyle.decoration(
            background: palette.card,
            borderRadius: HomeTheme.borderMd,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(HomeTheme.radiusMd),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: store != null
                      ? CatalogNetworkImage(
                          imageUrl: store!.displayHeroImageUrl,
                          thumbnailUrl: store!.displayHeroThumbUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          cacheHeight: 96,
                          fallback: SafeAssetImage(
                            asset: AppAssets.categoryFallback,
                            fallbackIcon: store!.categoryIcon,
                          ),
                        )
                      : ColoredBox(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            order.status.icon,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(HomeTheme.radiusMd),
                ),
                child: Text(
                  trackLabel,
                  style: HomeTypography.style(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
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

/// الأكثر مبيعًا — horizontal cards with store images from catalog.
class MatlobBestSellingSection extends StatelessWidget {
  const MatlobBestSellingSection({
    super.key,
    required this.stores,
    required this.onStoreTap,
    this.title = 'الأكثر مبيعًا 🔥',
  });

  final List<Store> stores;
  final void Function(Store store) onStoreTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: HomeTypography.style(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return _BestSellingChip(
                store: store,
                onTap: () => onStoreTap(store),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BestSellingChip extends StatelessWidget {
  const _BestSellingChip({required this.store, required this.onTap});

  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.card,
      borderRadius: HomeTheme.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: HomeTheme.borderMd,
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: HomeTheme.borderMd,
            border: Border.all(color: palette.border),
            boxShadow: HomeTheme.softShadowLight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(HomeTheme.radiusMd),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: CatalogNetworkImage(
                    imageUrl: store.displayHeroImageUrl,
                    thumbnailUrl: store.displayHeroThumbUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 104,
                    cacheHeight: 104,
                    fallback: SafeAssetImage(
                      asset: AppAssets.categoryFallback,
                      fallbackIcon: store.categoryIcon,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                store.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: HomeTypography.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
