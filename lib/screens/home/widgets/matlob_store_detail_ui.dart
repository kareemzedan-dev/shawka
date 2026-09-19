import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_operating_hours.dart';
import 'package:matlobgo/services/favorites_service.dart';

const matlobStoreSide = HomeTheme.pageHorizontal;
const _coverHeight = 248.0;

/// خلفية دمج الهيرو — متوافقة مع جسم الشاشة.
Color _heroBlendBg(AppPalette palette) =>
    palette.isDark ? palette.surface : const Color(0xFFF8FAFC);

/// قياسات موحّدة للاتساق البصري داخل شاشة المتجر.
abstract final class _StoreUi {
  static const double radiusCard = 16;
  static const double radiusImage = 14;
  static const double radiusChip = 22;
  static const double radiusSearch = 16;
  static const double productImage = 72;
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0E0A0A0A),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];
}

TextStyle matlobStoreCairo({
  required AppPalette palette,
  required double size,
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? height,
}) {
  return GoogleFonts.cairo(
    fontSize: size,
    fontWeight: weight,
    color: color ?? palette.textPrimary,
    height: height,
  );
}

List<Product> dedupeProductsById(List<Product> products) {
  final seen = <String>{};
  final result = <Product>[];
  for (final p in products) {
    if (seen.add(p.id)) result.add(p);
  }
  return result;
}

List<String> menuCategoriesFromProducts(List<Product> products) {
  final set = <String>{};
  for (final p in products) {
    final c = p.category.trim();
    if (c.isNotEmpty) set.add(c);
  }
  final list = set.toList()..sort();
  return list;
}

List<Product> popularMenuItems(List<Product> products) {
  final available = products.where((p) => p.isAvailable).toList()
    ..sort((a, b) {
      final byBest = (b.bestSeller ? 1 : 0).compareTo(a.bestSeller ? 1 : 0);
      if (byBest != 0) return byBest;
      final byFeat = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
      if (byFeat != 0) return byFeat;
      final byOrders = b.ordersCount.compareTo(a.ordersCount);
      if (byOrders != 0) return byOrders;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  if (available.isEmpty) return const [];
  final prioritized = available
      .where(
        (p) =>
            p.bestSeller ||
            p.isFeatured ||
            p.ordersCount > 0 ||
            p.sortOrder < 10,
      )
      .toList();
  final source = prioritized.length >= 2 ? prioritized : available;
  return source.take(3).toList();
}

/// تلميح ساعات العمل لبطاقة المتجر (إن وُجد جدول).
String storeHoursHint(Store store) {
  if (!store.isOpen) return 'مغلق حالياً';
  if (!store.operatingHours.hasSchedule) return 'مفتوح الآن';
  final day = store.operatingHours.day(DateTime.now().weekday);
  if (day.isClosed) return 'مفتوح الآن';
  return 'فتح حتى ${day.closeTime}';
}

List<Product> filterMenuProducts({
  required List<Product> products,
  required String query,
  String? category,
}) {
  var list = products;
  if (category != null && category.isNotEmpty) {
    list = list.where((p) => p.category.trim() == category).toList();
  }
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list
      .where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false),
      )
      .toList();
}

String storeSubtitle(Store store) {
  if (store.description != null && store.description!.trim().isNotEmpty) {
    return store.description!.trim();
  }
  if (store.tags.isNotEmpty) {
    return store.tags.take(3).join(' • ');
  }
  return store.categorySubtitle;
}

String storeShareText(Store store) {
  final fee = store.deliveryFee == 0
      ? 'توصيل مجاني'
      : 'رسوم التوصيل ${store.deliveryFee.toInt()} ج.م';
  final rating = store.rating > 0
      ? '⭐ ${store.rating.toStringAsFixed(1)} • '
      : '';
  return '${store.name}\n'
      '$rating${store.deliveryMinutes} دقيقة • $fee\n'
      '${storeSubtitle(store)}';
}

Future<void> showMatlobStoreInfoSheet(
  BuildContext context, {
  required Store store,
  required AppPalette palette,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      final feeLabel = store.deliveryFee == 0
          ? 'مجاني'
          : '${store.deliveryFee.toInt()} ج.م';
      final minLabel = store.minOrderAmount > 0
          ? '${store.minOrderAmount.toInt()} ج.م'
          : 'لا يوجد';
      final location = [
        if (store.governorate.trim().isNotEmpty) store.governorate.trim(),
        if (store.area.trim().isNotEmpty) store.area.trim(),
      ].join(' • ');

      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'معلومات المتجر',
                  textAlign: TextAlign.right,
                  style: matlobStoreCairo(
                    palette: palette,
                    size: 18,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoSheetRow(
                  palette: palette,
                  icon: Icons.storefront_rounded,
                  label: 'الاسم',
                  value: store.name,
                ),
                if (storeSubtitle(store).isNotEmpty)
                  _InfoSheetRow(
                    palette: palette,
                    icon: Icons.info_outline_rounded,
                    label: 'الوصف',
                    value: storeSubtitle(store),
                  ),
                if (location.isNotEmpty)
                  _InfoSheetRow(
                    palette: palette,
                    icon: Icons.location_on_outlined,
                    label: 'الموقع',
                    value: location,
                  ),
                if (store.rating > 0 || store.reviewCount > 0)
                  _InfoSheetRow(
                    palette: palette,
                    icon: Icons.star_rounded,
                    label: 'التقييم',
                    value: store.rating > 0
                        ? store.rating.toStringAsFixed(1)
                        : '${store.reviewCount} تقييم',
                  ),
                _InfoSheetRow(
                  palette: palette,
                  icon: Icons.schedule_rounded,
                  label: 'مدة التوصيل',
                  value: '${store.deliveryMinutes} دقيقة',
                ),
                _InfoSheetRow(
                  palette: palette,
                  icon: Icons.delivery_dining_rounded,
                  label: 'رسوم التوصيل',
                  value: feeLabel,
                ),
                _InfoSheetRow(
                  palette: palette,
                  icon: Icons.shopping_bag_outlined,
                  label: 'الحد الأدنى للطلب',
                  value: minLabel,
                ),
                _InfoSheetRow(
                  palette: palette,
                  icon: Icons.circle,
                  iconColor: store.isOpen ? AppColors.success : AppColors.error,
                  label: 'الحالة',
                  value: store.isOpen ? 'مفتوح الآن' : 'مغلق حالياً',
                  valueColor: store.isOpen
                      ? AppColors.success
                      : AppColors.error,
                ),
                if (store.discountLabel != null &&
                    store.discountLabel!.trim().isNotEmpty)
                  _InfoSheetRow(
                    palette: palette,
                    icon: Icons.local_offer_outlined,
                    label: 'العرض',
                    value: store.discountLabel!.trim(),
                    valueColor: AppColors.primary,
                  ),
                if (store.operatingHours.hasSchedule) ...[
                  const SizedBox(height: 8),
                  Text(
                    'أوقات العمل',
                    textAlign: TextAlign.right,
                    style: matlobStoreCairo(
                      palette: palette,
                      size: 15,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...StoreOperatingHours.dayLabels.entries.map((entry) {
                    final day = store.operatingHours.day(entry.key);
                    final line = day.isClosed
                        ? 'مغلق'
                        : '${day.openTime} - ${day.closeTime}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            line,
                            style: matlobStoreCairo(
                              palette: palette,
                              size: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            entry.value,
                            style: matlobStoreCairo(
                              palette: palette,
                              size: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showMatlobStoreFilterSheet(
  BuildContext context, {
  required AppPalette palette,
  required List<String> categories,
  required String? selected,
  required ValueChanged<String?> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'تصفية القائمة',
                  textAlign: TextAlign.right,
                  style: matlobStoreCairo(
                    palette: palette,
                    size: 18,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _FilterSheetChip(
                      label: 'الكل',
                      selected: selected == null,
                      palette: palette,
                      onTap: () {
                        onSelected(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    for (final c in categories)
                      _FilterSheetChip(
                        label: c,
                        selected: selected == c,
                        palette: palette,
                        onTap: () {
                          onSelected(c);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class MatlobStoreHeroHeader extends StatelessWidget {
  const MatlobStoreHeroHeader({
    super.key,
    required this.store,
    required this.palette,
    required this.onBack,
    this.scrollOffset = 0,
  });

  final Store store;
  final AppPalette palette;
  final VoidCallback onBack;

  /// إزاحة التمرير لـ Parallax خفيف (يُمرَّر من الـ ScrollView).
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final height = top + _coverHeight;
    final hasImage = (store.displayHeroImageUrl?.trim().isNotEmpty ?? false);
    final hasLogo =
        (store.displayLogoUrl?.trim().isNotEmpty ?? false) ||
        (store.displayLogoThumbUrl?.trim().isNotEmpty ?? false);
    final parallax = (scrollOffset * 0.28).clamp(0.0, 48.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // صورة الغلاف مع Parallax خفيف + عمق بصري.
          Transform.translate(
            offset: Offset(0, parallax),
            child: Transform.scale(
              scale: 1 + (parallax / height) * 0.08,
              alignment: Alignment.topCenter,
              child: hasImage
                  ? CatalogNetworkImage(
                      imageUrl: store.displayHeroImageUrl,
                      thumbnailUrl: store.displayHeroThumbUrl,
                      fit: BoxFit.cover,
                      cacheHeight: 560,
                      cacheWidth: 1080,
                      fallback: _HeroFallback(palette: palette),
                    )
                  : _HeroFallback(palette: palette),
            ),
          ),
          // تدرّج علوي ناعم للأيقونات فقط.
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
          // دمج ناعم للصورة مع المحتوى — Gradient فقط (بدون BackdropFilter
          // الذي كان يسبب شريط ضبابي بحد واضح).
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
                      _heroBlendBg(palette).withValues(alpha: 0.08),
                      _heroBlendBg(palette).withValues(alpha: 0.22),
                      _heroBlendBg(palette).withValues(alpha: 0.48),
                      _heroBlendBg(palette).withValues(alpha: 0.78),
                      _heroBlendBg(palette).withValues(alpha: 0.94),
                      _heroBlendBg(palette),
                    ],
                    stops: const [0, 0.12, 0.28, 0.48, 0.68, 0.86, 1],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: top + 6,
            start: matlobStoreSide,
            end: matlobStoreSide,
            child: Row(
              children: [
                _HeroIconButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  semanticLabel: 'رجوع',
                  onTap: onBack,
                ),
                const Spacer(),
                _HeroIconButton(
                  icon: Icons.share_rounded,
                  semanticLabel: 'مشاركة',
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: storeShareText(store)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ معلومات المتجر',
                          style: GoogleFonts.cairo(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _HeroFavoriteButton(storeId: store.id),
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
  const _HeroFallback({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary.withValues(alpha: 0.85),
            palette.isDark ? AppColors.surfaceMutedDark : AppColors.accentMuted,
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

class _HeroIconButton extends StatefulWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  State<_HeroIconButton> createState() => _HeroIconButtonState();
}

class _HeroIconButtonState extends State<_HeroIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 17, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

class _HeroFavoriteButton extends StatefulWidget {
  const _HeroFavoriteButton({required this.storeId});

  final String storeId;

  @override
  State<_HeroFavoriteButton> createState() => _HeroFavoriteButtonState();
}

class _HeroFavoriteButtonState extends State<_HeroFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final was = FavoritesService.instance.isFavorite(widget.storeId);
    await FavoritesService.instance.toggle(widget.storeId);
    if (!was && FavoritesService.instance.isFavorite(widget.storeId)) {
      _bounce.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final isFavorite =
            FavoritesService.instance.isFavorite(widget.storeId);
        return Semantics(
          button: true,
          label: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              _toggle();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.9 : 1,
              duration: const Duration(milliseconds: 110),
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.18).animate(
                  CurvedAnimation(parent: _bounce, curve: Curves.elasticOut),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isFavorite
                        ? AppColors.primary.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFavorite ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroLogoBadge extends StatelessWidget {
  const _HeroLogoBadge({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    // أصغر ~10% من السابق (70 → 63) مع ظل/حد رفيع.
    return Container(
      width: 63,
      height: 63,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E9F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
        child: CatalogNetworkImage(
          imageUrl: store.displayLogoUrl,
          thumbnailUrl: store.displayLogoThumbUrl,
          fit: BoxFit.contain,
          cacheWidth: 128,
          cacheHeight: 128,
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

class MatlobStoreMetaSection extends StatelessWidget {
  const MatlobStoreMetaSection({
    super.key,
    required this.store,
    required this.palette,
    this.onInfoTap,
  });

  final Store store;
  final AppPalette palette;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final feeLabel = store.deliveryFee == 0
        ? 'مجاني'
        : '${store.deliveryFee.toInt()} ج.م';
    final reviewLabel = store.reviewCount > 0
        ? store.reviewCount >= 500
            ? '500+'
            : '${store.reviewCount}'
        : null;
    final ratingText = store.rating > 0
        ? store.rating.toStringAsFixed(1) +
            (reviewLabel != null ? ' ($reviewLabel)' : '')
        : reviewLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        matlobStoreSide,
        10,
        matlobStoreSide,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            store.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: matlobStoreCairo(
                              palette: palette,
                              size: 24,
                              weight: FontWeight.w800,
                              height: 1.2,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        if (store.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7CF6).withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Color(0xFF2E7CF6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      storeSubtitle(store),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: matlobStoreCairo(
                        palette: palette,
                        size: 13,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (ratingText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.primary,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ratingText,
                                  style: matlobStoreCairo(
                                    palette: palette,
                                    size: 12.5,
                                    weight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: palette.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              storeHoursHint(store),
                              style: matlobStoreCairo(
                                palette: palette,
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(_StoreUi.radiusCard),
              border: Border.all(color: palette.border.withValues(alpha: 0.65)),
              boxShadow: _StoreUi.cardShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatusCell(
                      palette: palette,
                      icon: Icons.delivery_dining_rounded,
                      caption: 'التوصيل',
                      label: feeLabel,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  _StatusDivider(palette: palette),
                  Expanded(
                    child: _StatusCell(
                      palette: palette,
                      icon: Icons.schedule_rounded,
                      caption: 'الوقت',
                      label:
                          '${(store.deliveryMinutes - 5).clamp(10, 90)}-${(store.deliveryMinutes + 5).clamp(15, 120)} د',
                      iconColor: AppColors.primary,
                    ),
                  ),
                  _StatusDivider(palette: palette),
                  Expanded(
                    child: _StatusCell(
                      palette: palette,
                      icon: Icons.circle,
                      iconColor: store.isOpen
                          ? AppColors.success
                          : AppColors.error,
                      caption: 'الحالة',
                      label: store.isOpen ? 'مفتوح' : 'مغلق حالياً',
                      labelColor: store.isOpen
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  _StatusDivider(palette: palette),
                  Expanded(
                    child: _StatusCell(
                      palette: palette,
                      icon: Icons.info_outline_rounded,
                      caption: 'المزيد',
                      label: 'معلومات',
                      onTap: onInfoTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDivider extends StatelessWidget {
  const _StatusDivider({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: palette.border.withValues(alpha: 0.8));
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.palette,
    required this.icon,
    required this.label,
    this.caption,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  final AppPalette palette;
  final IconData icon;
  final String label;
  final String? caption;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor ?? palette.textSecondary),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: matlobStoreCairo(
                palette: palette,
                size: 10,
                weight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: matlobStoreCairo(
              palette: palette,
              size: 12.5,
              weight: FontWeight.w800,
              color: labelColor ?? AppColors.navy,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        child: child,
      ),
    );
  }
}

class MatlobStoreCategoryChips extends StatelessWidget {
  const MatlobStoreCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.palette,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          matlobStoreSide,
          4,
          matlobStoreSide,
          0,
        ),
        children: [
          _Chip(
            label: 'الكل',
            selected: selected == null,
            palette: palette,
            onTap: () => onSelected(null),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 10),
            _Chip(
              label: c,
              selected: selected == c,
              palette: palette,
              onTap: () => onSelected(c),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primary
                  : const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(_StoreUi.radiusChip),
              border: Border.all(
                color: widget.selected
                    ? AppColors.primary
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: matlobStoreCairo(
                palette: widget.palette,
                size: 13,
                weight: FontWeight.w700,
                color: widget.selected
                    ? AppColors.textOnPrimary
                    : widget.palette.textPrimary,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

class MatlobStoreMenuSearchBar extends StatefulWidget {
  const MatlobStoreMenuSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.palette,
    this.onFilterTap,
    this.hasActiveFilter = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppPalette palette;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilter;

  @override
  State<MatlobStoreMenuSearchBar> createState() =>
      _MatlobStoreMenuSearchBarState();
}

class _MatlobStoreMenuSearchBarState extends State<MatlobStoreMenuSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final hasText = widget.controller.text.isNotEmpty;
    final focused = widget.focusNode.hasFocus;
    final fill = focused
        ? Colors.white.withValues(alpha: 0.97)
        : const Color(0xFFF3F5F8).withValues(alpha: 0.96);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        matlobStoreSide,
        14,
        matlobStoreSide,
        0,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 52,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(_StoreUi.radiusSearch),
          border: Border.all(
            color: focused
                ? AppColors.primary.withValues(alpha: 0.42)
                : const Color(0xFFE6EAF0),
            width: focused ? 1.35 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: focused ? 0.07 : 0.04),
              blurRadius: focused ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: focused ? AppColors.primary : palette.textHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        textAlign: TextAlign.right,
                        cursorColor: AppColors.primary,
                        style: matlobStoreCairo(
                          palette: palette,
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'البحث في القائمة...',
                          hintStyle: matlobStoreCairo(
                            palette: palette,
                            size: 13.5,
                            color: palette.textHint,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (hasText)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: palette.textHint,
                        ),
                        onPressed: widget.controller.clear,
                      ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: focused
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : const Color(0xFFE0E4EA),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFilterTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.primary.withValues(alpha: 0.1),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 22,
                        color: widget.hasActiveFilter
                            ? AppColors.primary
                            : palette.textHint,
                      ),
                      if (widget.hasActiveFilter)
                        PositionedDirectional(
                          top: 12,
                          end: 12,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatlobStoreSectionHeader extends StatelessWidget {
  const MatlobStoreSectionHeader({
    super.key,
    required this.title,
    required this.palette,
    this.count,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String title;
  final AppPalette palette;
  final int? count;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        matlobStoreSide,
        8,
        matlobStoreSide,
        12,
      ),
      child: Column(
        children: [
          // فاصل بصري خفيف بين الأقسام.
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: palette.border.withValues(alpha: 0.7),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: palette.border.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (trailingLabel != null)
                TextButton(
                  onPressed: onTrailingTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    trailingLabel!,
                    style: matlobStoreCairo(
                      palette: palette,
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (count != null)
                Text(
                  '($count أصناف)',
                  style: matlobStoreCairo(
                    palette: palette,
                    size: 13,
                    color: palette.textHint,
                    weight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              Text(
                title,
                style: matlobStoreCairo(
                  palette: palette,
                  size: 17,
                  weight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MatlobStorePopularCard extends StatelessWidget {
  const MatlobStorePopularCard({
    super.key,
    required this.palette,
    required this.product,
    required this.enabled,
    required this.onOpen,
    required this.onAdd,
    this.onDecrement,
    this.quantity = 0,
  });

  final AppPalette palette;
  final Product product;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback? onDecrement;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final badge = product.badgeLabel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onOpen : null,
        borderRadius: BorderRadius.circular(_StoreUi.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.isDark ? palette.surface : Colors.white,
            borderRadius: BorderRadius.circular(_StoreUi.radiusCard),
            border: Border.all(
              color: palette.border.withValues(alpha: 0.55),
            ),
            boxShadow: _StoreUi.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: SizedBox(
              height: _StoreUi.productImage,
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(_StoreUi.radiusImage),
                        child: SizedBox(
                          width: _StoreUi.productImage,
                          height: _StoreUi.productImage,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CatalogNetworkImage(
                                imageUrl: product.imageUrl,
                                thumbnailUrl: product.imageThumbUrl,
                                fit: BoxFit.cover,
                                cacheWidth: 180,
                                cacheHeight: 180,
                                fallback: ColoredBox(
                                  color: palette.surfaceMuted,
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: palette.textHint
                                        .withValues(alpha: 0.5),
                                    size: 28,
                                  ),
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.08),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.05),
                                    ],
                                    stops: const [0, 0.5, 1],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (badge != null)
                        PositionedDirectional(
                          top: -4,
                          start: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: matlobStoreCairo(
                                palette: palette,
                                size: 9.5,
                                weight: FontWeight.w800,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: matlobStoreCairo(
                            palette: palette,
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        if ((product.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.description!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: matlobStoreCairo(
                              palette: palette,
                              size: 11.5,
                              color: palette.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          textAlign: TextAlign.right,
                          style: matlobStoreCairo(
                            palette: palette,
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  MatlobStoreAddButton(
                    enabled: enabled,
                    onTap: onAdd,
                    onDecrement: onDecrement,
                    quantity: quantity,
                    circular: true,
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

class MatlobStoreProductRow extends StatelessWidget {
  const MatlobStoreProductRow({
    super.key,
    required this.palette,
    required this.product,
    required this.enabled,
    required this.onOpen,
    required this.onAdd,
    this.onDecrement,
    this.quantity = 0,
  });

  final AppPalette palette;
  final Product product;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback? onDecrement;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final badge = product.badgeLabel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onOpen : null,
        borderRadius: BorderRadius.circular(_StoreUi.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
            height: _StoreUi.productImage,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_StoreUi.radiusImage),
                    child: SizedBox(
                      width: _StoreUi.productImage,
                      height: _StoreUi.productImage,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CatalogNetworkImage(
                            imageUrl: product.imageUrl,
                            thumbnailUrl: product.imageThumbUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 180,
                            cacheHeight: 180,
                            fallback: ColoredBox(
                              color: palette.surfaceMuted,
                              child: Icon(
                                Icons.storefront_rounded,
                                color: palette.textHint.withValues(alpha: 0.5),
                                size: 24,
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.05),
                                ],
                                stops: const [0, 0.5, 1],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (badge != null)
                    PositionedDirectional(
                      top: -3,
                      start: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          badge,
                          style: matlobStoreCairo(
                            palette: palette,
                            size: 9,
                            weight: FontWeight.w800,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: matlobStoreCairo(
                        palette: palette,
                        size: 14.5,
                        weight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    if (product.description != null &&
                        product.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        product.description!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: matlobStoreCairo(
                          palette: palette,
                          size: 11.5,
                          color: palette.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: matlobStoreCairo(
                        palette: palette,
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MatlobStoreAddButton(
                enabled: enabled,
                onTap: onAdd,
                onDecrement: onDecrement,
                quantity: quantity,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class MatlobStoreAddButton extends StatefulWidget {
  const MatlobStoreAddButton({
    super.key,
    required this.enabled,
    required this.onTap,
    this.onDecrement,
    this.quantity = 0,
    this.circular = false,
  });

  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onDecrement;
  final int quantity;
  final bool circular;

  @override
  State<MatlobStoreAddButton> createState() => _MatlobStoreAddButtonState();
}

class _MatlobStoreAddButtonState extends State<MatlobStoreAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty = widget.quantity;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: qty > 0
          ? _QuantityStepper(
              key: const ValueKey('stepper'),
              quantity: qty,
              enabled: widget.enabled,
              onMinus: widget.onDecrement,
              onPlus: widget.onTap,
            )
          : ScaleTransition(
              key: const ValueKey('add'),
              scale: Tween<double>(begin: 1, end: 0.9).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.45,
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  shape: widget.circular
                      ? const CircleBorder()
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.enabled
                        ? () {
                            _controller.forward().then((_) {
                              if (mounted) _controller.reverse();
                            });
                            widget.onTap();
                          }
                        : null,
                    onTapDown:
                        widget.enabled ? (_) => _controller.forward() : null,
                    onTapCancel:
                        widget.enabled ? () => _controller.reverse() : null,
                    splashColor: Colors.white.withValues(alpha: 0.28),
                    highlightColor: Colors.white.withValues(alpha: 0.12),
                    child: Ink(
                      width: widget.circular ? 42 : 44,
                      height: widget.circular ? 42 : 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        shape: widget.circular
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: widget.circular
                            ? null
                            : BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.34),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.textOnPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    super.key,
    required this.quantity,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIcon(
            icon: Icons.remove_rounded,
            onTap: enabled ? onMinus : null,
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          _StepperIcon(
            icon: Icons.add_rounded,
            onTap: enabled ? onPlus : null,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StepperIcon extends StatefulWidget {
  const _StepperIcon({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  State<_StepperIcon> createState() => _StepperIconState();
}

class _StepperIconState extends State<_StepperIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: widget.filled ? AppColors.navy : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: null,
            splashColor: widget.filled
                ? Colors.white.withValues(alpha: 0.22)
                : AppColors.navy.withValues(alpha: 0.1),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                widget.icon,
                size: 17,
                color: widget.filled ? Colors.white : AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSheetRow extends StatelessWidget {
  const _InfoSheetRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  final AppPalette palette;
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: matlobStoreCairo(
                palette: palette,
                size: 13.5,
                weight: FontWeight.w600,
                color: valueColor ?? palette.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: matlobStoreCairo(
                  palette: palette,
                  size: 10.5,
                  color: palette.textHint,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSheetChip extends StatelessWidget {
  const _FilterSheetChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : const Color(0xFFF0F1F3),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: matlobStoreCairo(
              palette: palette,
              size: 13,
              weight: FontWeight.w700,
              color: selected ? Colors.white : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
