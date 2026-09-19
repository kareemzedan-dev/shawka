import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
/// Premium navy hero shell — shared between mobile home and web landing.
class CatalogHomeHeader extends StatelessWidget {
  const CatalogHomeHeader({
    super.key,
    required this.child,
    this.padding,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(child: CatalogHeroBackground()),
        if (padding != null)
          Padding(padding: padding!, child: child)
        else
          child,
      ],
    );

    if (!clip) return body;
    return ClipRect(child: body);
  }
}

/// Diagonal navy gradient + pattern overlay.
class CatalogHeroBackground extends StatelessWidget {
  const CatalogHeroBackground({super.key});

  static const Color gradientStart = Color(0xFF0A0A0A);
  static const Color gradientMiddle = Color(0xFF1A1A1A);
  static const Color gradientEnd = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [gradientStart, gradientMiddle, gradientEnd],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: -80,
            end: -40,
            child: _RadialGlow(
              size: 220,
              colors: [
                AppColors.primary.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ),
          ),
          PositionedDirectional(
            bottom: -60,
            start: -30,
            child: _RadialGlow(
              size: 180,
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _HeroPatternPainter()),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  AppColors.white.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _drawDotGrid(canvas, size);
    _drawCurves(canvas, size);
  }

  void _drawDotGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  void _drawCurves(Canvas canvas, Size size) {
    final curvePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.35,
        size.width * 0.95,
        size.height * 0.62,
      );
    canvas.drawPath(path1, curvePaint);

    final goldCurve = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path2 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.65,
        size.width * 0.9,
        size.height * 0.9,
      );
    canvas.drawPath(path2, goldCurve);
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) => false;
}
