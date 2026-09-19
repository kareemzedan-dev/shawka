import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_section.dart';

class CheckoutCouponCard extends StatelessWidget {
  const CheckoutCouponCard({
    super.key,
    required this.palette,
    required this.expanded,
    required this.code,
    required this.discount,
    required this.controller,
    required this.title,
    required this.hint,
    required this.applyLabel,
    required this.ctaSubtitle,
    required this.savingsTemplate,
    required this.onToggle,
    required this.onApply,
    required this.onRemove,
  });

  final AppPalette palette;
  final bool expanded;
  final String code;
  final double discount;
  final TextEditingController controller;
  final String title;
  final String hint;
  final String applyLabel;
  final String ctaSubtitle;
  final String savingsTemplate;
  final VoidCallback onToggle;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final applied = code.isNotEmpty && discount > 0;
    return CheckoutSurfaceCard(
      palette: palette,
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: title,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(CheckoutTokens.radiusXl - 6),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: CheckoutTokens.spaceLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applied ? code : title,
                          style: CartTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(
                          applied
                              ? savingsTemplate.replaceAll(
                                  '{amount}',
                                  discount.toStringAsFixed(0),
                                )
                              : ctaSubtitle,
                          style: CartTypography.style(
                            fontSize: 12,
                            color: applied
                                ? AppColors.success
                                : palette.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (applied)
                    Semantics(
                      button: true,
                      label: 'إزالة الكوبون',
                      child: IconButton(
                        onPressed: onRemove,
                        tooltip: 'إزالة الكوبون',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    )
                  else
                    AnimatedRotation(
                      duration: CheckoutTokens.motionFast,
                      turns: expanded ? 0.25 : 0,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 17,
                        color: palette.textHint,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: CheckoutTokens.motionStandard,
            curve: CheckoutTokens.curveStandard,
            child: !expanded || applied
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => onApply(),
                            style: CartTypography.style(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: hint,
                              filled: true,
                              fillColor: palette.surfaceMuted,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: CheckoutTokens.spaceXl,
                                vertical: CheckoutTokens.spaceLg,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: CheckoutTokens.spaceMd - 1),
                        Semantics(
                          button: true,
                          label: applyLabel,
                          child: FilledButton(
                            onPressed: onApply,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                76,
                                CheckoutTokens.touchTarget + 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: Text(
                              applyLabel,
                              style: CartTypography.style(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
