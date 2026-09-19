import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/home_typography.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';

/// Shawka | Skeena Home Design System — spacing, radius, typography, shadows.
abstract final class HomeTheme {
  // ── Spacing ──
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  /// مقياس الصفحة الرئيسية — هوامش وأقسام أضيق لمظهر أرقى وأكثر تنظيماً.
  static const double pageHorizontal = 16;
  static const double sectionGap = 24;
  static const double blockGap = 12;
  static const double itemGap = 10;

  // ── Border Radius (Small 12 · Medium 20 · Large 24) ──
  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 24;

  static BorderRadius get borderSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderLg => BorderRadius.circular(radiusLg);

  // ── Motion ──
  static const Duration animStandard = Duration(milliseconds: 250);
  static const Duration animPress = Duration(milliseconds: 120);
  static const Duration animFast = Duration(milliseconds: 250);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  // ── Typography ──
  static TextStyle get heroEyebrow => HomeTypography.style(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.white.withValues(alpha: 0.6),
        height: 1.2,
        letterSpacing: 0.3,
      );

  static TextStyle get heroTitle => HomeTypography.style(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle sectionTitle(AppPalette palette) => HomeTypography.style(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionSubtitle => HomeTypography.style(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get sectionAction => HomeTypography.style(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.1,
      );

  static TextStyle storeName(AppPalette palette) => HomeTypography.style(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        height: 1.2,
        letterSpacing: -0.12,
      );

  static TextStyle storeMeta(AppPalette palette) => HomeTypography.style(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: palette.textSecondary,
      );

  static TextStyle get chipLabel => HomeTypography.style(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.15,
      );

  static TextStyle get navLabel => HomeTypography.style(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1,
      );

  static TextStyle get badgeLabel => HomeTypography.style(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        height: 1,
      );

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => softShadowLight;
  static List<BoxShadow> get cardShadowSelected => softShadowSelected;

  static List<BoxShadow> softShadow(AppPalette palette) => [
        BoxShadow(
          color: (palette.isDark ? AppColors.black : AppColors.navy)
              .withValues(alpha: palette.isDark ? 0.35 : 0.04),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadowLight => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadowFloating => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.025),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadowLifted => softShadowFloating;

  static List<BoxShadow> get softShadowSelected => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get softShadowSearch => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.04),
          blurRadius: 28,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get softShadowNav => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.035),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get softShadowChip => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 18,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get categorySelectedGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.22),
          blurRadius: 22,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get featuredCardGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        ...softShadowLight,
      ];

  static List<BoxShadow> get trendingCardGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.18),
          blurRadius: 28,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadowNavActive => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.14),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get softShadowGlass => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}
