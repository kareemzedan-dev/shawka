import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product_addon.dart';
import 'package:matlobgo/screens/home/product/widgets/product_description_section.dart';

/// اختيار الإضافات — يؤثّر على سعر الوحدة (يُحسب في الـ Controller).
class ProductAddons extends StatelessWidget {
  const ProductAddons({
    super.key,
    required this.addons,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<ProductAddon> addons;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (addons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProductSectionTitle(title: 'إضافات اختيارية'),
        const SizedBox(height: ProductTokens.spaceLg),
        ...addons.map(
          (addon) => Padding(
            padding: const EdgeInsets.only(bottom: ProductTokens.spaceMd),
            child: _AddonTile(
              addon: addon,
              selected: selectedIds.contains(addon.id),
              onToggle: () => onToggle(addon.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddonTile extends StatelessWidget {
  const _AddonTile({
    required this.addon,
    required this.selected,
    required this.onToggle,
  });

  final ProductAddon addon;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final priceLabel = addon.price <= 0
        ? 'مجاني'
        : '+ ${addon.price.toStringAsFixed(0)} ج.م';

    return Semantics(
      button: true,
      checked: selected,
      label: '${addon.name} $priceLabel',
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
        child: AnimatedContainer(
          duration: ProductTokens.motionFast,
          curve: ProductTokens.curveStandard,
          constraints: const BoxConstraints(minHeight: ProductTokens.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: ProductTokens.space2xl,
            vertical: ProductTokens.spaceLg,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : ProductTokens.cardFill,
            borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              _CheckBox(selected: selected),
              const SizedBox(width: ProductTokens.spaceLg),
              Expanded(
                child: Text(
                  addon.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CartTypography.style(
                    fontSize: ProductTokens.bodySize,
                    fontWeight: FontWeight.w600,
                    color: ProductTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: ProductTokens.spaceMd),
              Text(
                priceLabel,
                style: CartTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: addon.price <= 0
                      ? ProductTokens.textMuted
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFD1D5DB),
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
