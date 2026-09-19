import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/widgets/product_hero_actions.dart';

/// الـ hero: صورة كاملة + تدرّج سفلي + شريحة المتجر + عنوان المنتج + شرائح داكنة.
class ProductHero extends StatelessWidget {
  const ProductHero({
    super.key,
    required this.store,
    required this.product,
    required this.isFavorite,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
  });

  final Store store;
  final Product product;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top + ProductTokens.heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CatalogNetworkImage(
            imageUrl: product.imageUrl,
            thumbnailUrl: product.imageThumbUrl,
            fit: BoxFit.cover,
            cacheWidth: 1000,
            cacheHeight: 800,
            useFullResolution: true,
            fallback: const ColoredBox(
              color: Color(0xFFF3F4F6),
              child: Icon(
                Icons.storefront_rounded,
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
            top: top + ProductTokens.spaceSm,
            left: ProductTokens.pagePadding,
            right: ProductTokens.pagePadding,
            child: ProductHeroActions(
              isFavorite: isFavorite,
              onBack: onBack,
              onShare: onShare,
              onToggleFavorite: onToggleFavorite,
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
              child: CatalogNetworkImage(
                imageUrl: store.displayLogoUrl,
                thumbnailUrl: store.displayLogoThumbUrl,
                fit: BoxFit.cover,
                cacheWidth: 96,
                cacheHeight: 96,
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
            constraints: const BoxConstraints(maxWidth: 180),
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
