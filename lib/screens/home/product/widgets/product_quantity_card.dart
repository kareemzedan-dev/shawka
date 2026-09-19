import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';

/// بطاقة الكمية: عنوان + وصف + عدّاد (+ ذهبي، − رمادي).
class ProductQuantityCard extends StatelessWidget {
  const ProductQuantityCard({
    super.key,
    required this.quantity,
    required this.canIncrement,
    required this.canDecrement,
    required this.onIncrement,
    required this.onDecrement,
    this.subtitle = 'اختر الكمية المناسبة لطلبك',
  });

  final int quantity;
  final bool canIncrement;
  final bool canDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ProductTokens.space2xl),
      decoration: BoxDecoration(
        color: ProductTokens.cardFill,
        borderRadius: BorderRadius.circular(ProductTokens.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الكمية',
                  style: CartTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ProductTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: CartTypography.style(
                    fontSize: ProductTokens.captionSize,
                    fontWeight: FontWeight.w500,
                    color: ProductTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            container: true,
            label: 'الكمية $quantity',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperButton(
                  icon: Icons.remove_rounded,
                  filled: false,
                  enabled: canDecrement,
                  semanticLabel: 'إنقاص الكمية',
                  onTap: onDecrement,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProductTokens.space2xl,
                  ),
                  child: Text(
                    '$quantity',
                    style: CartTypography.style(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: ProductTokens.textPrimary,
                    ),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  filled: true,
                  enabled: canIncrement,
                  semanticLabel: 'زيادة الكمية',
                  onTap: onIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.filled,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color iconColor;
    if (filled) {
      background = enabled ? AppColors.primary : const Color(0xFFE5E7EB);
      iconColor = enabled ? AppColors.textOnPrimary : ProductTokens.textMuted;
    } else {
      background = ProductTokens.surfaceMuted;
      iconColor = enabled ? ProductTokens.textPrimary : const Color(0xFFCBD2DB);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: ProductTokens.stepperButton,
            height: ProductTokens.stepperButton,
            child: Icon(icon, size: ProductTokens.stepperIcon, color: iconColor),
          ),
        ),
      ),
    );
  }
}
