import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

/// Design tokens لشاشة تفاصيل المنتج — متوافقة مع Cart Reference Implementation v1
/// (تعيد استخدام [CartTokens] حيث يناسب، وتضيف قياسات PDP الخاصة).
abstract final class ProductTokens {
  // ── Surfaces / brand (مشتركة مع السلة للاتساق) ──
  static const Color accentText = CartTokens.accentText;
  static const Color ctaBackground = CartTokens.ctaBackground;
  static const Color dangerText = CartTokens.dangerText;
  static const Color surfaceMuted = CartTokens.surfaceMuted;

  /// خلفية الورقة البيضاء المتراكبة على الـ hero.
  static const Color sheet = Colors.white;

  /// نص ثانوي/وصف.
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// حقول الملاحظات والبطاقات الرمادية.
  static const Color fieldFill = Color(0xFFF3F5F8);
  static const Color cardFill = Color(0xFFF5F6F8);

  /// شرائح داكنة فوق الصورة (تقييم/وقت/طلبات).
  static const Color heroChipBackground = Color(0xE6111827);
  static const Color heroChipText = Colors.white;

  /// نجمة التقييم.
  static const Color star = Color(0xFFFFB800);

  /// شارة الخصم (أخضر).
  static const Color discountBadgeBackground = Color(0xFFE7F7EE);
  static const Color discountBadgeText = Color(0xFF15803D);

  /// شارة الأكثر مبيعاً (ذهبي فاتح).
  static const Color bestSellerBadgeBackground = AppColors.accentMuted;
  static const Color bestSellerBadgeText = CartTokens.accentText;

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

  /// نصف قطر الحافة العلوية للورقة البيضاء المتراكبة.
  static const double sheetRadius = 28;

  // ── Sizes ──
  static const double heroHeight = 320;

  /// مقدار تراكب الورقة البيضاء فوق الـ hero.
  static const double sheetOverlap = 40;
  static const double touchTarget = CartTokens.touchTarget;

  /// أزرار الخطّاف (+/−) ≥ 48 لاستيفاء الحد الأدنى لمساحة اللمس (A11y).
  static const double stepperButton = 48;
  static const double stepperIcon = 20;
  static const double storeLogo = 34;
  static const double ctaHeight = 56;
  static const double ctaChevron = 28;
  static const double suggestionWidth = 158;
  static const double suggestionImageHeight = 104;
  static const double suggestionAddButton = 32;
  static const double attributeIcon = 22;
  static const double noteMaxLength = 200;

  // ── Typography sizes ──
  static const double titleSize = 22;
  static const double priceSize = 24;
  static const double oldPriceSize = 15;
  static const double sectionTitleSize = 17;
  static const double bodySize = 14;
  static const double chipSize = 12.5;
  static const double badgeSize = 12;
  static const double captionSize = 11.5;

  // ── Motion (نفس منحنى السلة) ──
  static const Duration motionFast = CartTokens.motionFast;
  static const Duration motionStandard = CartTokens.motionStandard;
  static const Curve curveStandard = CartTokens.curveStandard;
  static const Curve curveIn = CartTokens.curveIn;
  static const double ctaPressScale = CartTokens.continuePressScale;

  // ── Shadows ──
  static List<BoxShadow> get sheetShadow => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get ctaBarShadow => CartTokens.continueBarShadow;

  static List<BoxShadow> get heroButtonShadow => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.18),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get suggestionShadow => CartTokens.suggestionShadow;
}
