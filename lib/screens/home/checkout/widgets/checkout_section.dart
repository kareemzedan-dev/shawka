import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';

class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: CheckoutTokens.spaceXs / 2,
            bottom: CheckoutTokens.spaceMd + 1,
          ),
          child: Text(
            title,
            style: CartTypography.style(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class CheckoutSurfaceCard extends StatelessWidget {
  const CheckoutSurfaceCard({
    super.key,
    required this.palette,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final AppPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(CheckoutTokens.radiusXl),
        boxShadow: CheckoutTokens.cardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
