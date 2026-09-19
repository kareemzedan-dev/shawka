import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// Semantic colors that adapt between light and dark mode.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.borderLight,
    required this.accentMuted,
    required this.navBarColor,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color borderLight;
  final Color accentMuted;
  final Color navBarColor;
  final bool isDark;

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    card: AppColors.surface,
    surfaceMuted: AppColors.surfaceMuted,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    border: AppColors.border,
    borderLight: AppColors.borderLight,
    accentMuted: AppColors.accentMuted,
    navBarColor: AppColors.backgroundBottom,
    isDark: false,
  );

  static const dark = AppPalette(
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    card: AppColors.surfaceContainerDark,
    surfaceMuted: AppColors.surfaceMutedDark,
    textPrimary: AppColors.textOnDark,
    textSecondary: Color(0xFFA3A3A3),
    textHint: Color(0xFF737373),
    border: AppColors.borderDark,
    borderLight: Color(0xFF222222),
    accentMuted: AppColors.accentMutedDark,
    navBarColor: AppColors.surfaceDark,
    isDark: true,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? borderLight,
    Color? accentMuted,
    Color? navBarColor,
    bool? isDark,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      accentMuted: accentMuted ?? this.accentMuted,
      navBarColor: navBarColor ?? this.navBarColor,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      navBarColor: Color.lerp(navBarColor, other.navBarColor, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
