import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';

/// عنوان قسم بشريط برتقالي — نمط موحّد لأقسام الورقة البيضاء.
class ProductSectionTitle extends StatelessWidget {
  const ProductSectionTitle({
    super.key,
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: ProductTokens.spaceMd),
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            title,
            style: CartTypography.style(
              fontSize: ProductTokens.sectionTitleSize,
              fontWeight: FontWeight.w800,
              color: ProductTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// قسم «المكونات والتفاصيل»: الوصف + شرائح المكونات إن وُجدت.
class ProductDescriptionSection extends StatelessWidget {
  const ProductDescriptionSection({
    super.key,
    required this.product,
    required this.storeName,
  });

  final Product product;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final description = product.description?.trim().isNotEmpty == true
        ? product.description!.trim()
        : '${product.name} — طبق طازج من $storeName.';
    final ingredients = product.ingredients
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProductSectionTitle(title: 'المكونات والتفاصيل'),
        const SizedBox(height: ProductTokens.spaceLg),
        Text(
          description,
          style: CartTypography.style(
            fontSize: ProductTokens.bodySize,
            fontWeight: FontWeight.w500,
            color: ProductTokens.textSecondary,
            height: 1.7,
          ),
        ),
        if (ingredients.isNotEmpty) ...[
          const SizedBox(height: ProductTokens.space2xl),
          Wrap(
            spacing: ProductTokens.spaceSm,
            runSpacing: ProductTokens.spaceSm,
            children: ingredients
                .map((label) => _IngredientChip(label: label))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ProductTokens.cardFill,
        borderRadius: BorderRadius.circular(ProductTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: ProductTokens.discountBadgeText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: CartTypography.style(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ProductTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
