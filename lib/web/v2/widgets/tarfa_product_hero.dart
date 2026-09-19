import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/widgets/product_hero_actions.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

/// Hero لصفحة المنتج على الويب — نفس تجربة التطبيق مع [TarfaWebImage].
class TarfaProductHero extends StatelessWidget {
  const TarfaProductHero({
    super.key,
    required this.store,
    required this.product,
    required this.onBack,
    required this.onShare,
    this.heroHeight = ProductTokens.heroHeight,
  });

  final Store store;
  final Product product;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final safeTop = top > 0 ? top : ProductTokens.spaceLg;

    return SizedBox(
      height: safeTop + heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TarfaWebImage(
            kind: TarfaImageKind.product,
            fill: true,
            imageUrl: product.imageUrl,
            thumbnailUrl: product.imageThumbUrl,
            useFullResolution: true,
            fallback: const ColoredBox(
              color: Color(0xFFF3F4F6),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 72,
                color: Color(0xFFB6BDC7),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x40000000),
                  Color(0x00000000),
                  Color(0x99000000),
                ],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          Positioned(
            top: safeTop + ProductTokens.spaceSm,
            left: ProductTokens.pagePadding,
            right: ProductTokens.pagePadding,
            child: Row(
              children: [
                ProductHeroCircleButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  semanticLabel: 'رجوع',
                  onTap: onBack,
                ),
                const Spacer(),
                ProductHeroCircleButton(
                  icon: Icons.share_outlined,
                  semanticLabel: 'مشاركة المنتج',
                  onTap: onShare,
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: ProductTokens.pagePadding,
            end: ProductTokens.pagePadding,
            bottom: ProductTokens.sheetOverlap + ProductTokens.space2xl,
            child: _HeroContent(store: store, product: product),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.store, required this.product});

  final Store store;
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StoreChip(store: store),
        const SizedBox(height: ProductTokens.spaceMd),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CartTypography.style(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: ProductTokens.spaceMd),
        _HeroChipsRow(product: product),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ProductTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ProductTokens.radiusPill),
            child: SizedBox(
              width: ProductTokens.storeLogo,
              height: ProductTokens.storeLogo,
              child: TarfaWebImage(
                kind: TarfaImageKind.storeLogo,
                fill: true,
                imageUrl: store.displayLogoUrl,
                thumbnailUrl: store.displayLogoThumbUrl,
                fallback: const ColoredBox(
                  color: ProductTokens.cardFill,
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: ProductTokens.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: ProductTokens.spaceSm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CartTypography.style(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ProductTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChipsRow extends StatelessWidget {
  const _HeroChipsRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (product.rating > 0) {
      chips.add(
        _HeroChip(
          icon: Icons.star_rounded,
          iconColor: ProductTokens.star,
          label: product.rating.toStringAsFixed(1),
        ),
      );
    }
    if (product.preparationTime > 0) {
      chips.add(
        _HeroChip(
          icon: Icons.schedule_rounded,
          label: '${product.preparationTime} دقيقة',
        ),
      );
    }
    if (product.ordersCount > 0) {
      chips.add(
        _HeroChip(
          icon: Icons.local_fire_department_rounded,
          label: '${product.ordersCount} طلب',
        ),
      );
    } else {
      chips.add(
        const _HeroChip(icon: Icons.fiber_new_rounded, label: 'جديد'),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: ProductTokens.spaceSm,
      runSpacing: ProductTokens.spaceSm,
      children: chips,
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ProductTokens.heroChipBackground,
        borderRadius: BorderRadius.circular(ProductTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: CartTypography.style(
              fontSize: ProductTokens.chipSize,
              fontWeight: FontWeight.w700,
              color: ProductTokens.heroChipText,
            ),
          ),
        ],
      ),
    );
  }
}
