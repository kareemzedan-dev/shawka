import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Arabic typography for the customer home experience.
abstract final class HomeTypography {
  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.alexandria(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }
}
