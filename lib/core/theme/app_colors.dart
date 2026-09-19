import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';

/// Shawka | Skeena design system — palette extracted from the official logo
/// (matte charcoal monogram + metallic gold knife, true-black field).
///
/// Identity colors (`primary` / `secondary`) come from White Label
/// [BrandingValues]. Semantic tokens below complete the UI system.
abstract final class AppColors {
  // ── Brand identity (White Label) ──
  static const Color primary = Color(BrandingValues.primaryValue);
  static const Color primaryDark = Color(BrandingValues.primaryDarkValue);
  static const Color primaryLight = Color(BrandingValues.primaryLightValue);

  /// Ink / charcoal — former `navy` slot; kept for call-site compatibility.
  static const Color navy = Color(BrandingValues.secondaryValue);
  static const Color navyLight = Color(BrandingValues.secondaryLightValue);
  static const Color navyMuted = Color(0xFF2A2A2A);

  static const Color ink = navy;
  static const Color inkElevated = navyLight;
  static const Color inkMuted = navyMuted;

  static const Color accent = Color(BrandingValues.accentValue);
  static const Color gold = primary;
  static const Color goldBright = primaryLight;
  static const Color goldDeep = primaryDark;

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Light surfaces ──
  static const Color background = Color(0xFFF7F7F5);
  static const Color backgroundBottom = Color(0xFFF0F0EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFEFED);
  static const Color surfaceContainer = Color(0xFFF3F3F1);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E6);

  // ── Dark surfaces ──
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceMutedDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerDark = Color(0xFF1C1C1C);
  static const Color surfaceContainerHighDark = Color(0xFF242424);

  // ── Text ──
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textHint = Color(0xFF8A8A8A);
  static const Color textOnPrimary = Color(0xFF0A0A0A);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textGold = primary;

  // ── Borders / dividers ──
  static const Color border = Color(0xFFE4E4E1);
  static const Color borderLight = Color(0xFFEEEEEC);
  static const Color borderStrong = Color(0xFFD0D0CC);
  static const Color borderDark = Color(0xFF2C2C2C);
  static const Color divider = Color(0xFFE8E8E6);
  static const Color dividerDark = Color(0xFF2A2A2A);
  static const Color borderGold = Color(0xFF8E6D2F);

  // ── Icons ──
  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textSecondary;
  static const Color iconActive = primary;
  static const Color iconDisabled = Color(0xFFB0B0B0);
  static const Color iconOnDark = Color(0xFFF5F5F5);

  // ── Brand soft fills ──
  static const Color accentSoft = Color(0x1AD4AF37);
  static const Color accentMuted = Color(0xFFF8F1DE);
  static const Color accentMutedDark = Color(0xFF1F1A10);

  // ── Semantic ──
  static const Color success = Color(0xFF1B7A4E);
  static const Color successContainer = Color(0xFFE6F5EE);
  static const Color warning = Color(0xFFB8860B);
  static const Color warningContainer = Color(0xFFFBF3DC);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFDECEA);
  static const Color info = Color(0xFF2F5D8C);
  static const Color infoContainer = Color(0xFFE8F0F8);

  // ── Badges / chips ──
  static const Color badgeBackground = primary;
  static const Color badgeForeground = textOnPrimary;
  static const Color chipBackground = surfaceContainer;
  static const Color chipSelected = accentMuted;
  static const Color chipBorder = border;

  // ── Overlay / skeleton / shimmer ──
  static const Color overlay = Color(0x99000000);
  static const Color overlayLight = Color(0x33000000);
  static const Color skeleton = Color(0xFFE8E8E6);
  static const Color skeletonDark = Color(0xFF2A2A2A);
  static const Color shimmerBase = Color(0xFFEFEFED);
  static const Color shimmerHighlight = Color(0xFFFAFAF8);
  static const Color shimmerBaseDark = Color(0xFF1F1F1F);
  static const Color shimmerHighlightDark = Color(0xFF2E2E2E);

  // ── State colors ──
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledContainer = Color(0xFFF0F0EE);
  static const Color hover = Color(0x14D4AF37);
  static const Color pressed = Color(0x29D4AF37);
  static const Color focus = Color(0x66D4AF37);

  // ── Shadow tint ──
  static const Color shadow = Color(0xFF000000);
  static const Color shadowGold = Color(0xFFD4AF37);

  // ── Radius scale ──
  static BorderRadius get radiusXs => BorderRadius.circular(8);
  static BorderRadius get radiusSm => BorderRadius.circular(12);
  static BorderRadius get radiusMd => BorderRadius.circular(16);
  static BorderRadius get radiusLg => BorderRadius.circular(20);
  static BorderRadius get radiusXl => BorderRadius.circular(24);
  static BorderRadius get radiusPill => BorderRadius.circular(999);

  static const double rXs = 8;
  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 20;
  static const double rXl = 24;

  // ── Soft premium shadows ──
  static List<BoxShadow> get elevationSoft => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevationCard => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.05),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: shadow.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevationGold => [
        BoxShadow(
          color: shadowGold.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevationFloating => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.06),
          blurRadius: 36,
          offset: const Offset(0, 12),
        ),
      ];

  // ── Gradients (logo-derived only) ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient goldMetallicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF1D27B), Color(0xFFD4AF37), Color(0xFF8E6D2F)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient inkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A), Color(0xFF000000)],
  );

  static const LinearGradient homeHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF000000)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
  );

  static const LinearGradient splashGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF000000)],
  );

  static LinearGradient splashGradientFor(bool isDark) =>
      isDark ? splashGradientDark : splashGradient;

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A), Color(0xFF000000)],
    stops: [0.0, 0.55, 1.0],
  );

  static const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static SystemUiOverlayStyle homeOverlay({required bool isDark}) =>
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? surfaceDark : white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      );
}
