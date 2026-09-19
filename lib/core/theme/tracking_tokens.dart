import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

/// Design tokens لشاشة تتبع الطلب — RI v7.
abstract final class TrackingTokens {
  static const Color accent = AppColors.primary;
  static const Color accentText = CartTokens.accentText;
  static const Color live = AppColors.success;
  static const Color verified = AppColors.success;
  static const Color navy = AppColors.navy;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textHint;
  static const Color sheetBg = AppColors.surface;
  static const Color cardBorder = AppColors.border;
  static const Color timelineDone = AppColors.primary;
  static const Color timelinePending = Color(0xFFD1D5DB);
  static const Color callButton = AppColors.ink;
  static const Color chatButton = AppColors.surfaceMuted;

  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double pagePadding = 16;
  static const double sheetRadius = 28;
  static const double cardRadius = 16;
  static const double touchTarget = 48;
  static const double backButton = 42;
  static const double driverAvatar = 52;
  static const double timelineDot = 28;
  static const double radiusPill = 999;

  static const Duration motionFast = CartTokens.motionFast;
  static const Duration motionStandard = CartTokens.motionStandard;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}
