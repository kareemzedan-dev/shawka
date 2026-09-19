import 'package:flutter/material.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

abstract final class TarfaTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: TarfaTokens.background,
      colorScheme: const ColorScheme.light(
        primary: TarfaTokens.primary,
        onPrimary: Colors.white,
        secondary: TarfaTokens.secondary,
        onSecondary: Colors.white,
        surface: TarfaTokens.surface,
        onSurface: TarfaTokens.textPrimary,
        error: TarfaTokens.error,
      ),
      dividerColor: TarfaTokens.divider,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: TarfaTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: TarfaTokens.borderRadius,
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TarfaTokens.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: TarfaTokens.s24,
            vertical: TarfaTokens.s16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TarfaTokens.borderRadius,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TarfaTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TarfaTokens.s16,
          vertical: TarfaTokens.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: TarfaTokens.borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TarfaTokens.borderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TarfaTokens.borderRadius,
          borderSide: BorderSide(
            color: TarfaTokens.secondary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TarfaTokens.surface,
        selectedColor: TarfaTokens.secondary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TarfaTokens.radius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TarfaTokens.s12,
          vertical: TarfaTokens.s8,
        ),
      ),
    );
  }
}
