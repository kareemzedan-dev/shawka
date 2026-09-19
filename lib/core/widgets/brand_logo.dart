import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

enum BrandLogoStyle {
  /// Full logo on transparent / matching black field.
  standalone,

  /// Soft dark plate — for light headers / colored surfaces.
  onColored,

  /// Subtle gold-rim plate — for dark backgrounds (splash / hero).
  onDark,

  /// Cream plate mark (auth) — soft gold ambient, no nested dark frame.
  authHero,
}

/// Displays the Shawka | Skeena official logo.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width = 150,
    this.style = BrandLogoStyle.onColored,
    this.asset,
  });

  final double width;
  final BrandLogoStyle style;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final path = asset ??
        (style == BrandLogoStyle.authHero ? AppAssets.authLogo : AppAssets.logo);

    final image = Image.asset(
      path,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    return switch (style) {
      BrandLogoStyle.standalone => image,
      BrandLogoStyle.authHero => _AuthHeroLogo(width: width, child: image),
      BrandLogoStyle.onColored => _FrostedLogoPlate(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: AppColors.rLg,
          fillColor: AppColors.black.withValues(alpha: 0.92),
          borderColor: AppColors.primary.withValues(alpha: 0.35),
          child: image,
        ),
      BrandLogoStyle.onDark => _FrostedLogoPlate(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: AppColors.rXl,
          fillColor: AppColors.white.withValues(alpha: 0.04),
          borderColor: AppColors.primary.withValues(alpha: 0.28),
          blurSigma: 16,
          child: image,
        ),
    };
  }
}

class _AuthHeroLogo extends StatelessWidget {
  const _AuthHeroLogo({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 32,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child,
      ),
    );
  }
}

class _FrostedLogoPlate extends StatelessWidget {
  const _FrostedLogoPlate({
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.fillColor,
    required this.borderColor,
    this.blurSigma = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color fillColor;
  final Color borderColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowGold.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
