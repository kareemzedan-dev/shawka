import 'dart:math' as math;

import 'package:flutter/material.dart';

/// حساب تباين WCAG 2.1 بين لونين.
abstract final class WcagContrast {
  /// النسبة وفق الصيغة الرسمية (L1+0.05)/(L2+0.05).
  static double ratio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double relativeLuminance(Color color) {
    final r = _channel(color.r);
    final g = _channel(color.g);
    final b = _channel(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _channel(double c) {
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  /// نص عادي: AA ≥ 4.5
  static bool passesAaNormal(Color foreground, Color background) =>
      ratio(foreground, background) >= 4.5;

  /// نص كبير (≥18pt أو 14pt bold): AA ≥ 3.0
  static bool passesAaLarge(Color foreground, Color background) =>
      ratio(foreground, background) >= 3.0;

  /// AAA نص عادي ≥ 7.0
  static bool passesAaaNormal(Color foreground, Color background) =>
      ratio(foreground, background) >= 7.0;
}

/// أزواج ألوان السلة الخاضعة للتدقيق.
class CartContrastPair {
  const CartContrastPair({
    required this.id,
    required this.foreground,
    required this.background,
    required this.requireAaNormal,
  });

  final String id;
  final Color foreground;
  final Color background;
  final bool requireAaNormal;
}
