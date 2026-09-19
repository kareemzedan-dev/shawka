import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// Shared tokens for Notifications / Search / Favorites polish.
abstract final class UiPolishTokens {
  static const background = AppColors.background;
  static const backgroundBottom = AppColors.backgroundBottom;
  static const navy = AppColors.ink;
  static const success = AppColors.success;
  static const warning = AppColors.warning;

  static const radiusLg = AppColors.rXl;
  static const radiusMd = AppColors.rMd;
  static const radiusSm = AppColors.rSm;

  static const spaceXs = 8.0;
  static const spaceSm = 12.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;

  static TextStyle titleLg(Color color) => GoogleFonts.cairo(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  static TextStyle titleMd(Color color) => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.1,
      );

  static TextStyle body(Color color) => GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.45,
      );

  static TextStyle caption(Color color) => GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static List<BoxShadow> get cardShadow => AppColors.elevationCard;

  static BoxDecoration glass({Color? tint}) => BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      );
}
