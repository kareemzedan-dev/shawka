import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// Web v2 design tokens — brand identity colors from [AppColors].
abstract final class TarfaTokens {
  // Brand colors (identity → White Label via AppColors)
  static const Color primary = AppColors.navy;
  static const Color primaryLight = AppColors.navyLight;
  static const Color secondary = AppColors.primary;
  static const Color secondaryLight = AppColors.primaryLight;
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = AppColors.navy;
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textMuted = Color(0xFF8A8A8A);
  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color divider = Color(0xFFE4E4E1);

  // 8pt grid spacing
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s80 = 80;

  static const double radius = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  static const double maxWidth = 1280;
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;

  /// Grid aspect ratios sized for TarfaStoreCard / TarfaProductCard content.
  /// (width / height) — lower = taller card to avoid overflow on mobile.
  static double storeGridAspectRatio(bool isMobile) => isMobile ? 0.78 : 0.70;

  static double productGridAspectRatio(bool isMobile) => isMobile ? 0.72 : 0.64;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: primary.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get shadowHover => [
    BoxShadow(
      color: primary.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static TextStyle displayLarge(BuildContext context) => GoogleFonts.cairo(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium(BuildContext context) => GoogleFonts.cairo(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.cairo(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: textPrimary,
  );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: textPrimary,
  );

  static TextStyle titleLarge(BuildContext context) => GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: textPrimary,
  );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: textSecondary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textSecondary,
  );

  static TextStyle labelLarge(BuildContext context) => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: textPrimary,
  );

  static TextStyle labelMedium(BuildContext context) => GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: textSecondary,
  );

  static Duration get animFast => const Duration(milliseconds: 200);
  static Duration get animNormal => const Duration(milliseconds: 320);
  static Duration get animSlow => const Duration(milliseconds: 480);

  static Curve get curve => Curves.easeOutCubic;
}
