import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/ui_polish_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/favorites_service.dart';

class FavoritesPolishHeader extends StatelessWidget {
  const FavoritesPolishHeader({
    super.key,
    required this.count,
    this.countLabel,
    this.leading,
  });

  final int count;
  final String? countLabel;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.inkElevated,
                  UiPolishTokens.navy,
                  AppColors.black,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -20,
          left: -20,
          child: Icon(
            Icons.favorite_rounded,
            size: 120,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'المفضلة',
                          style: UiPolishTokens.titleLg(Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      count == 0
                          ? 'موردوك ومنتجاتك المحفوظة'
                          : countLabel ?? '$count محفوظ',
                      style: UiPolishTokens.body(
                        Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PolishedFavoriteCard extends StatefulWidget {
  const PolishedFavoriteCard({
    super.key,
    required this.store,
    required this.onTap,
    this.featured = false,
    this.onRemoved,
  });

  final Store store;
  final VoidCallback? onTap;
  final bool featured;
  final void Function(Store store)? onRemoved;

  @override
  State<PolishedFavoriteCard> createState() => _PolishedFavoriteCardState();
}

class _PolishedFavoriteCardState extends State<PolishedFavoriteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = FavoritesService.instance.isFavorite(widget.store.id);
    if (wasFavorite) {
      await FavoritesService.instance.remove(widget.store.id);
      widget.onRemoved?.call(widget.store);
    } else {
      await FavoritesService.instance.toggle(widget.store.id);
      _heartCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final delivery = store.deliveryFee == 0
        ? 'مجاني'
        : '${store.deliveryFee.toInt()} ج';
    final height = widget.featured ? 200.0 : 160.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(UiPolishTokens.radiusLg),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(UiPolishTokens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiPolishTokens.radiusLg),
            border: widget.featured
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  )
                : Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: UiPolishTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(UiPolishTokens.radiusLg),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: height,
                      width: double.infinity,
                      child: CatalogNetworkImage(
                        imageUrl: store.displayHeroImageUrl,
                        thumbnailUrl: store.displayHeroThumbUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 720,
                        cacheHeight: 400,
                        fallback: SafeAssetImage(
                          asset: AppAssets.categoryFallback,
                          fallbackIcon: store.categoryIcon,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              UiPolishTokens.navy.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _AnimatedHeart(
                        controller: _heartCtrl,
                        onTap: _toggleFavorite,
                      ),
                    ),
                    if (widget.featured)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'الأكثر طلباً',
                            style: GoogleFonts.cairo(
                              color: AppColors.textOnPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (!store.isOpen)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'مغلق حالياً',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 12,
                      right: 14,
                      left: 14,
                      child: Text(
                        store.name,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: widget.featured ? 20 : 17,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    if (store.rating > 0 || store.reviewCount > 0) ...[
                      _Badge(
                        icon: Icons.star_rounded,
                        label: store.rating > 0
                            ? store.rating.toStringAsFixed(1)
                            : '${store.reviewCount} تقييم',
                        highlight: true,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _Badge(
                      icon: Icons.schedule_rounded,
                      label: '${store.deliveryMinutes} د',
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.delivery_dining_rounded,
                      label: delivery,
                    ),
                    const Spacer(),
                    Text(
                      store.categoryLabel,
                      style: UiPolishTokens.caption(AppColors.textHint),
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

class _AnimatedHeart extends StatelessWidget {
  const _AnimatedHeart({required this.controller, required this.onTap});

  final AnimationController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
        builder: (context, child) {
          final scale = 1 + (controller.value * 0.2);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.1)
            : const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

void showFavoriteUndoSnackBar(BuildContext context, Store store) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: UiPolishTokens.navy,
      content: Text(
        'تمت إزالة ${store.name} من المفضلة',
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
      ),
      action: SnackBarAction(
        label: 'تراجع',
        textColor: AppColors.primaryLight,
        onPressed: () => FavoritesService.instance.toggle(store.id),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

void showFavoriteProductUndoSnackBar(
  BuildContext context, {
  required String storeId,
  required String productId,
  required String productName,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: UiPolishTokens.navy,
      content: Text(
        'تمت إزالة $productName من المفضلة',
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
      ),
      action: SnackBarAction(
        label: 'تراجع',
        textColor: AppColors.primaryLight,
        onPressed: () =>
            FavoritesService.instance.toggleProduct(storeId, productId),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

/// بطاقة منتج مفضّل — صورة + اسم + سعر + متجر.
class PolishedFavoriteProductCard extends StatelessWidget {
  const PolishedFavoriteProductCard({
    super.key,
    required this.product,
    required this.storeName,
    required this.onTap,
    required this.onRemove,
  });

  final Product product;
  final String storeName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(UiPolishTokens.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiPolishTokens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiPolishTokens.radiusLg),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: UiPolishTokens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: CatalogNetworkImage(
                      imageUrl: product.imageUrl,
                      thumbnailUrl: product.imageThumbUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                      cacheHeight: 160,
                      fallback: const ColoredBox(
                        color: Color(0xFFF3F5FA),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
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
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: UiPolishTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiPolishTokens.caption(AppColors.textHint),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${product.price.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة من المفضلة',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
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
