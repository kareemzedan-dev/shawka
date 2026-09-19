import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

/// Design tokens لشاشة Checkout — متوافقة مع Cart Reference Implementation v1.
abstract final class CheckoutTokens {
  // ── Surfaces (مشاركة سلة حيث يناسب الاتساق) ──
  static const Color surfaceMuted = CartTokens.surfaceMuted;
  static const Color accentText = CartTokens.accentText;
  static const Color ctaBackground = CartTokens.ctaBackground;
  static const Color dangerText = CartTokens.dangerText;

  // ── Spacing ──
  static const double spaceXs = CartTokens.spaceXs;
  static const double spaceSm = CartTokens.spaceSm;
  static const double spaceMd = CartTokens.spaceMd;
  static const double spaceLg = CartTokens.spaceLg;
  static const double spaceXl = CartTokens.spaceXl;
  static const double space2xl = CartTokens.space2xl;
  static const double space3xl = CartTokens.space3xl;
  static const double pagePadding = CartTokens.pagePadding;
  static const double listBottomClearance = 120;

  // ── Radius ──
  static const double radiusSm = CartTokens.radiusSm;
  static const double radiusMd = CartTokens.radiusMd;
  static const double radiusLg = CartTokens.radiusLg;
  static const double radiusXl = CartTokens.radiusXl;
  static const double radius2xl = CartTokens.radius2xl;
  static const double radiusPill = CartTokens.radiusPill;

  // ── Sizes ──
  static const double touchTarget = CartTokens.touchTarget;
  static const double confirmButtonHeight = 54;
  static const double mapPreviewHeight = 120;
  static const double paymentLogo = 36;
  static const double lineThumb = 64;

  // ── Motion (نفس منحنى السلة) ──
  static const Duration motionFast = CartTokens.motionFast;
  static const Duration motionStandard = CartTokens.motionStandard;
  static const Duration quoteDebounce = Duration(milliseconds: 350);
  static const Curve curveStandard = CartTokens.curveStandard;
  static const double confirmPressScale = CartTokens.continuePressScale;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => CartTokens.cardShadow;
  static List<BoxShadow> get confirmBarShadow => CartTokens.continueBarShadow;

  static Color get headerColor => AppColors.navy;
}
