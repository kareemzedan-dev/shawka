import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/order.dart';

/// Success hero: scale + pulse ring + animated check + fade.
class OrderSuccessHero extends StatelessWidget {
  const OrderSuccessHero({
    super.key,
    required this.scale,
    required this.fade,
    required this.pulse,
    required this.checkProgress,
    required this.palette,
  });

  final Animation<double> scale;
  final Animation<double> fade;
  final Animation<double> pulse;
  final Animation<double> checkProgress;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final successBg = palette.isDark
        ? AppColors.success.withValues(alpha: 0.22)
        : AppColors.success.withValues(alpha: 0.14);
    final ringAlpha = palette.isDark ? 0.28 : 0.2;

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: pulse,
                builder: (context, child) {
                  final spread = 10 + pulse.value * 18;
                  return Container(
                    width: 72 + spread,
                    height: 72 + spread,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(
                        alpha: ringAlpha * (1 - pulse.value * 0.85),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: successBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(
                      alpha: palette.isDark ? 0.45 : 0.28,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(
                        alpha: palette.isDark ? 0.18 : 0.12,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: checkProgress,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SuccessCheckPainter(
                        progress: checkProgress.value,
                        color: AppColors.success,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCheckPainter extends CustomPainter {
  _SuccessCheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.2, size.width * 0.07)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.7)
      ..lineTo(size.width * 0.76, size.height * 0.32);

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.clamp(0, 1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessCheckPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

const String _kSupplierEmoji = '📦';

/// Compact order summary below the success message.
class OrderConfirmationSummaryCard extends StatelessWidget {
  const OrderConfirmationSummaryCard({
    super.key,
    required this.order,
    required this.palette,
    required this.paymentLabel,
  });

  final Order order;
  final AppPalette palette;
  final String paymentLabel;

  @override
  Widget build(BuildContext context) {
    final itemLabel = order.itemCount == 1
        ? 'عنصر واحد'
        : '${order.itemCount} عناصر';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                _kSupplierEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  itemLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              Text(
                '${order.grandTotal.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: HomeTheme.borderSm,
              border: Border.all(
                color: palette.border.withValues(alpha: 0.85),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 15,
                  color: palette.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    paymentLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ETA card with stronger visual hierarchy.
class OrderConfirmationEtaCard extends StatelessWidget {
  const OrderConfirmationEtaCard({
    super.key,
    required this.etaMinutes,
    required this.palette,
  });

  final int etaMinutes;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: palette.isDark
              ? [const Color(0xFF1A2838), palette.card]
              : [AppColors.white, AppColors.accentMuted],
        ),
        borderRadius: HomeTheme.borderMd,
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: palette.isDark ? 0.32 : 0.22,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: palette.isDark ? 0.1 : 0.12,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🛵 سيصل طلبك خلال',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$etaMinutes دقيقة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Staggered fade + slide for cards and text blocks.
class OrderConfirmationReveal extends StatelessWidget {
  const OrderConfirmationReveal({
    super.key,
    required this.animation,
    required this.interval,
    required this.child,
    this.slideOffset = 0.08,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: interval);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, slideOffset * 28 * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

enum OrderConfirmationButtonStyle { primary, secondary, tertiary }

/// Press feedback for confirmation CTAs.
class OrderConfirmationButton extends StatefulWidget {
  const OrderConfirmationButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.palette,
    required this.style,
  });

  final String label;
  final VoidCallback onPressed;
  final AppPalette palette;
  final OrderConfirmationButtonStyle style;

  @override
  State<OrderConfirmationButton> createState() =>
      _OrderConfirmationButtonState();
}

class _OrderConfirmationButtonState extends State<OrderConfirmationButton> {
  bool _pressed = false;

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: HomeTheme.animPress,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    switch (widget.style) {
      case OrderConfirmationButtonStyle.primary:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: HomeTheme.borderMd,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: widget.palette.isDark ? 0.28 : 0.32,
                ),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textOnPrimary,
            ),
          ),
        );
      case OrderConfirmationButtonStyle.secondary:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.palette.isDark
                ? widget.palette.surfaceMuted
                : AppColors.white,
            borderRadius: HomeTheme.borderMd,
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: widget.palette.isDark ? 0.45 : 0.35,
              ),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        );
      case OrderConfirmationButtonStyle.tertiary:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.palette.textSecondary,
              decoration: TextDecoration.underline,
              decorationColor:
                  widget.palette.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        );
    }
  }
}
