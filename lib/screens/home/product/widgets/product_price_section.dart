import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';

/// السعر (برتقالي) + السعر القديم مشطوب + شارات (خصم % أخضر، الأكثر مبيعاً خوخي).
class ProductPriceSection extends StatelessWidget {
  const ProductPriceSection({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasOldPrice =
        product.oldPrice > product.price && product.oldPrice > 0;
    final discount = product.effectiveDiscountPercent.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${product.price.toStringAsFixed(0)} ج.م',
              style: CartTypography.style(
                fontSize: ProductTokens.priceSize,
                fontWeight: FontWeight.w900,
                color: ProductTokens.accentText,
                height: 1,
              ),
            ),
            if (hasOldPrice) ...[
              const SizedBox(width: ProductTokens.spaceMd),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${product.oldPrice.toStringAsFixed(0)} ج.م',
                  style: CartTypography.style(
                    fontSize: ProductTokens.oldPriceSize,
                    fontWeight: FontWeight.w600,
                    color: ProductTokens.textMuted,
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
              ),
            ],
          ],
        ),
        if (discount > 0 || product.bestSeller) ...[
          const SizedBox(height: ProductTokens.spaceMd),
          Wrap(
            spacing: ProductTokens.spaceSm,
            runSpacing: ProductTokens.spaceSm,
            children: [
              if (discount > 0)
                _Badge(
                  label: 'خصم $discount%',
                  background: ProductTokens.discountBadgeBackground,
                  color: ProductTokens.discountBadgeText,
                ),
              if (product.bestSeller)
                const _Badge(
                  label: 'الأكثر مبيعاً',
                  background: ProductTokens.bestSellerBadgeBackground,
                  color: ProductTokens.bestSellerBadgeText,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.color,
  });

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ProductTokens.radiusPill),
      ),
      child: Text(
        label,
        style: CartTypography.style(
          fontSize: ProductTokens.badgeSize,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
