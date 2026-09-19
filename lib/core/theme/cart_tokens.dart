import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// Design tokens لشاشة السلة — مرجع بصري موحّد (بدون magic numbers).
abstract final class CartTokens {
  // ── Surfaces ──
  static const Color surfaceMuted = Color(0xFFF1F1EF);
  static const Color noteFill = Color(0xFFF5F5F3);
  static const Color progressTrack = Color(0xFFECECE9);
  static const Color dashedBorder = Color(0xFFD4D4D0);
  static const Color couponActionBorder = Color(0xFFE0E0DC);

  /// Deep bronze for text on light surfaces — AA ≥ 4.5.
  static const Color accentText = Color(0xFF6B5420);

  /// Ink CTA — white label on black (premium restaurant).
  static const Color ctaBackground = Color(0xFF0A0A0A);

  /// أحمر نصّي — AA normal على أبيض.
  static const Color dangerText = Color(0xFFC62828);

  // ── Spacing ──
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 10;
  static const double spaceLg = 12;
  static const double spaceXl = 14;
  static const double space2xl = 16;
  static const double space3xl = 20;
  static const double pagePadding = 16;
  static const double headerHorizontal = 18;
  static const double headerBottom = 28;
  static const double listBottomClearance = 108;
  static const double freeCardOverlap = 22;

  // ── Radius ──
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 18;
  static const double radiusXl = 20;
  static const double radius2xl = 22;
  static const double radiusPill = 999;

  // ── Sizes ──
  static const double stepperHeight = 48;
  static const double stepperIcon = 20;
  static const double touchTarget = 48;
  static const double backButton = 44;
  static const double productImage = 92;
  static const double suggestionWidth = 124;
  static const double suggestionImageHeight = 96;
  static const double suggestionAddButton = 30;
  static const double continueButtonHeight = 54;
  static const double continueArrow = 28;
  static const double freeIcon = 34;
  static const double progressHeight = 7;
  static const double couponBusySize = 16;

  // ── Typography sizes ──
  static const double titleSize = 24;
  static const double sectionTitleSize = 16;
  static const double itemTitleSize = 14.5;
  static const double priceSize = 15;
  static const double totalSize = 20;
  static const double bodySize = 13.5;
  static const double captionSize = 12.5;
  static const double metaSize = 11.5;
  static const double badgeSize = 10;

  // ── Motion ──
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionStandard = Duration(milliseconds: 250);
  static const Duration motionProgress = Duration(milliseconds: 450);
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveIn = Curves.easeInCubic;
  static const double continuePressScale = 0.97;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get freeCardShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.1),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get continueBarShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get suggestionShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
