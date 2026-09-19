import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

/// Design tokens لشاشة الطلبات — متوافقة مع Cart Reference Implementation v1
/// (تعيد استخدام [CartTokens] حيث يناسب، وتضيف قياسات Orders الخاصة بالتصميم).
abstract final class OrdersTokens {
  // ── Brand / accent (مشتركة مع السلة للاتساق واجتياز WCAG) ──
  /// برونز داكن للنص/الأسعار على خلفية فاتحة — AA normal ≥ 4.5.
  static const Color accentText = CartTokens.accentText;

  /// خلفية زر التتبّع (حبر أسود) — أبيض عليها يحقق AA normal ≥ 4.5.
  static const Color ctaBackground = CartTokens.ctaBackground;
  static const Color dangerText = CartTokens.dangerText;

  // ── Surfaces ──
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFF0F1F3);

  /// تعبئة بطاقة الوقت المتوقّع (رمادي فاتح).
  static const Color etaCardFill = Color(0xFFF5F6F8);
  static const Color etaCardBorder = Color(0xFFECEEF1);

  /// شريحة الأقسام (segmented) الرمادية + الحبّة البيضاء المحدّدة.
  static const Color segmentTrack = Color(0xFFF0F1F3);
  static const Color segmentSelected = Colors.white;

  /// تعبئة رابط «تفاصيل الطلب» ومعاينة المنتجات.
  static const Color detailsFill = Color(0xFFF3F4F6);
  static const Color previewFill = Color(0xFFF5F6F8);

  // ── Text ──
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// نص التبويب غير المحدّد على `segmentTrack` — أغمق لاجتياز WCAG AA.
  static const Color segmentUnselectedText = Color(0xFF4B5563);

  /// نجمة التقييم.
  static const Color star = Color(0xFFFFB800);

  /// شارة التوثيق (أزرق).
  static const Color verified = Color(0xFF2E7CF6);

  // ── Timeline ──
  static const Color timelineDone = AppColors.primary;
  static const Color timelineCurrent = AppColors.primary;
  static const Color timelineFuture = Color(0xFFD1D5DB);
  static const Color timelineTrack = Color(0xFFE5E7EB);

  // ── Spacing ──
  static const double spaceXs = CartTokens.spaceXs;
  static const double spaceSm = CartTokens.spaceSm;
  static const double spaceMd = CartTokens.spaceMd;
  static const double spaceLg = CartTokens.spaceLg;
  static const double spaceXl = CartTokens.spaceXl;
  static const double space2xl = CartTokens.space2xl;
  static const double space3xl = CartTokens.space3xl;
  static const double pagePadding = CartTokens.pagePadding;

  // ── Radius ──
  static const double radiusSm = CartTokens.radiusSm;
  static const double radiusMd = CartTokens.radiusMd;
  static const double radiusLg = CartTokens.radiusLg;
  static const double radiusXl = CartTokens.radiusXl;
  static const double radiusPill = CartTokens.radiusPill;

  /// نصف قطر بطاقة الطلب (تصميم SSOT ~22).
  static const double cardRadius = 22;

  // ── Sizes ──
  static const double touchTarget = CartTokens.touchTarget;

  /// شعار المتجر الدائري في رأس البطاقة.
  static const double storeLogo = 48;

  /// حبّة الخطوة في الخط الزمني الأفقي.
  static const double timelineDot = 28;
  static const double timelineIcon = 15;

  /// ارتفاع زر «تتبع الطلب مباشرة».
  static const double trackButtonHeight = 52;

  /// شرائح الأقسام (≥ 48 لاستيفاء الحد الأدنى لمساحة اللمس A11y).
  static const double segmentHeight = 48;

  /// صورة المنتج في المعاينة.
  static const double previewImage = 56;

  /// شارة «+N» الدائرية.
  static const double previewMoreBadge = 40;

  // ── Typography sizes ──
  static const double storeNameSize = 16;
  static const double metaSize = 11.5;
  static const double priceSize = 17;
  static const double timelineLabelSize = 10.5;
  static const double etaTitleSize = 12.5;
  static const double etaValueSize = 15;
  static const double segmentSize = 12.5;

  // ── Motion (نفس منحنى السلة) ──
  static const Duration motionFast = CartTokens.motionFast;
  static const Duration motionStandard = CartTokens.motionStandard;
  static const Curve curveStandard = CartTokens.curveStandard;
  static const Curve curveIn = CartTokens.curveIn;
  static const double pressScale = CartTokens.continuePressScale;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get trackButtonShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get segmentShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get timelineGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.35),
          blurRadius: 10,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ];
}
