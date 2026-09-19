import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';

class CheckoutPaymentCard extends StatelessWidget {
  const CheckoutPaymentCard({
    super.key,
    required this.palette,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final CheckoutPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${method.name}، ${method.description}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CheckoutTokens.radiusLg),
          child: AnimatedContainer(
            duration: CheckoutTokens.motionStandard,
            curve: CheckoutTokens.curveStandard,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: CheckoutTokens.spaceXl,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(CheckoutTokens.radiusLg),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.75)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: CheckoutTokens.cardShadow,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: method.logoUrl.isEmpty
                        ? const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.primary,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(CheckoutTokens.spaceSm),
                            child: CachedNetworkImage(
                              imageUrl: method.logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) => const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CartTypography.style(
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CartTypography.style(
                          fontSize: 12,
                          color: palette.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: CheckoutTokens.motionFast,
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    key: ValueKey(selected),
                    color: selected ? AppColors.primary : palette.textHint,
                    size: 24,
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
