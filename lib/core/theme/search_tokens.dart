import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

/// Design tokens لشاشة البحث — متوافقة مع Cart RI v1 / Orders RI v4
/// ومطابقة لتصميم SSOT المعتمد لشاشة البحث.
abstract final class SearchTokens {
  // ── Brand / surfaces ──
  static const Color accent = AppColors.primary;
  static const Color accentText = CartTokens.accentText;
  static const Color heroNavy = AppColors.navy;
  static const Color heroNavyMid = AppColors.inkElevated;
  static const Color heroNavyDeep = AppColors.black;
  static const Color bodyBackground = AppColors.background;
  static const Color cardBackground = AppColors.surface;
  static const Color chipIdleFill = AppColors.surface;
  static const Color chipIdleBorder = AppColors.border;
  static const Color popularChipFill = AppColors.surfaceMuted;
  static const Color popularHot = AppColors.error;
  static const Color openBadge = AppColors.success;
  static const Color closedBadge = AppColors.error;
  static const Color verified = AppColors.info;
  static const Color star = Color(0xFFFFB800);
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textHint;
  static const Color dangerText = CartTokens.dangerText;
  static const Color glassFill = Color(0x33FFFFFF);

  // ── Spacing ──
  static const double spaceXs = CartTokens.spaceXs;
  static const double spaceSm = CartTokens.spaceSm;
  static const double spaceMd = CartTokens.spaceMd;
  static const double spaceLg = CartTokens.spaceLg;
  static const double spaceXl = CartTokens.spaceXl;
  static const double space2xl = CartTokens.space2xl;
  static const double space3xl = CartTokens.space3xl;
  static const double pagePadding = 16;

  // ── Radius ──
  static const double radiusSm = CartTokens.radiusSm;
  static const double radiusMd = CartTokens.radiusMd;
  static const double radiusLg = CartTokens.radiusLg;
  static const double radiusXl = CartTokens.radiusXl;
  static const double radiusPill = CartTokens.radiusPill;
  static const double bodyTopRadius = 28;
  static const double searchFieldRadius = 28;
  static const double cardRadius = 16;
  static const double categoryCircle = 52;

  // ── Sizes ──
  static const double touchTarget = CartTokens.touchTarget;
  static const double headerButton = 42;
  static const double searchFieldHeight = 52;
  static const double categoryRowHeight = 92;
  static const double filterChipHeight = 40;
  /// ارتفاع صورة كارت المتجر — مضغوط لمظهر أرقى وأكثر تنظيماً.
  static const double storeCardImageHeight = 124;
  static const double recentRowHeight = 48;
  static const int resultsPageSize = 20;
  static const Duration debounce = Duration(milliseconds: 300);

  // ── Typography ──
  static const double titleSize = 22;
  static const double sectionTitleSize = 15;
  static const double storeNameSize = 14.5;
  static const double bodySize = 13;
  static const double captionSize = 11;
  static const double metaSize = 11;
  static const double badgeSize = 10;

  // ── Motion ──
  static const Duration motionFast = CartTokens.motionFast;
  static const Duration motionStandard = CartTokens.motionStandard;
  static const Curve curveStandard = CartTokens.curveStandard;
  static const double pressScale = CartTokens.continuePressScale;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [AppColors.inkElevated, AppColors.ink, AppColors.black],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get searchFieldShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
