import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';

/// بطاقات السمات (سعرات/حصة/طبيعة) — تُخفى القيم الفارغة، ولا يظهر الصف إن كانت كلها فارغة.
class ProductAttributes extends StatelessWidget {
  const ProductAttributes({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cards = <_AttributeData>[
      if (product.calories > 0)
        _AttributeData(
          icon: Icons.local_fire_department_rounded,
          value: '${product.calories}',
          label: 'سعرة حرارية',
        ),
      if (product.portionSize.trim().isNotEmpty)
        _AttributeData(
          icon: Icons.lunch_dining_rounded,
          value: product.portionSize.trim(),
          label: 'الحصة',
        ),
      if (product.natureLabel.trim().isNotEmpty)
        _AttributeData(
          icon: Icons.eco_rounded,
          value: product.natureLabel.trim(),
          label: 'الطبيعة',
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: _AttributeCard(data: cards[i])),
          if (i != cards.length - 1)
            const SizedBox(width: ProductTokens.spaceMd),
        ],
      ],
    );
  }
}

class _AttributeData {
  const _AttributeData({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}

class _AttributeCard extends StatelessWidget {
  const _AttributeCard({required this.data});

  final _AttributeData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data.label} ${data.value}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ProductTokens.spaceMd,
          vertical: ProductTokens.space2xl,
        ),
        decoration: BoxDecoration(
          color: ProductTokens.cardFill,
          borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
        ),
        child: Column(
          children: [
            Icon(
              data.icon,
              size: ProductTokens.attributeIcon,
              color: AppColors.primary,
            ),
            const SizedBox(height: ProductTokens.spaceSm),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: ProductTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: ProductTokens.captionSize,
                fontWeight: FontWeight.w600,
                color: ProductTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
