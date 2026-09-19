import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';

/// Premium app background — subtle gradient (#F8FAFC → #F2F5F9) + light noise.
abstract final class PremiumBackground {
  static const top = Color(0xFFF8FAFC);
  static const bottom = Color(0xFFF2F5F9);

  static const decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    ),
  );

  static bool isEnabled(BuildContext context) =>
      !(Theme.of(context).extension<AppPalette>()?.isDark ?? false);

  /// Scaffold: transparent in light mode so the global layer shows through.
  static Color scaffoldColor(BuildContext context) {
    if (!isEnabled(context)) {
      return Theme.of(context).extension<AppPalette>()?.background ??
          AppColors.background;
    }
    return Colors.transparent;
  }

  /// Wrap tab bodies / scroll areas (light mode only).
  static Widget body(BuildContext context, Widget child) {
    if (!isEnabled(context)) {
      return ColoredBox(
        color: context.palette.background,
        child: child,
      );
    }
    return PremiumBackgroundLayer(child: child);
  }
}

/// Static backdrop (gradient + noise) for app root.
class PremiumBackgroundBackdrop extends StatelessWidget {
  const PremiumBackgroundBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: PremiumBackground.decoration,
      child: _NoiseOverlay(),
    );
  }
}

/// Full-bleed gradient + noise behind content areas (light mode).
class PremiumBackgroundLayer extends StatelessWidget {
  const PremiumBackgroundLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: PremiumBackground.decoration,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          const Positioned.fill(child: _NoiseOverlay()),
          child,
        ],
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PremiumNoisePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PremiumNoisePainter extends CustomPainter {
  _PremiumNoisePainter();

  static final List<Offset> _normPoints = _generatePoints();

  static List<Offset> _generatePoints() {
    final random = math.Random(42);
    return List.generate(1400, (_) {
      return Offset(random.nextDouble(), random.nextDouble());
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A0A0A).withValues(alpha: 0.022);
    final w = size.width;
    final h = size.height;
    for (final p in _normPoints) {
      final radius = 0.45 + (p.dx * 0.35);
      canvas.drawCircle(Offset(p.dx * w, p.dy * h), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumNoisePainter oldDelegate) => false;
}
