import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

/// Design tokens لشاشة حسابي — RI v8.
abstract final class ProfileTokens {
  static const Color navy = AppColors.navy;
  static const Color navyLight = AppColors.navyLight;
  static const Color accent = AppColors.primary;
  static const Color accentText = CartTokens.accentText;
  static const Color heart = Color(0xFFC45C3E);
  static const Color actionIcon = Color(0xFFB8860B);
  static const Color textOnNavy = Colors.white;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textHint;
  static const Color sheetBg = AppColors.surface;
  static const Color cardBorder = AppColors.border;
  static const Color activityBg = AppColors.surfaceMuted;
  static const Color toggleOff = Color(0xFFD1D5DB);

  static const double pagePadding = 16;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double headerRadius = 0;
  static const double heroRadius = 20;
  static const double cardRadius = 16;
  static const double actionRadius = 14;
  static const double settingsRadius = 16;
  static const double avatarSize = 64;
  static const double editBadge = 26;
  static const double touchTarget = 48;

  static const Duration motionFast = CartTokens.motionFast;
  static const Duration motionStandard = CartTokens.motionStandard;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
