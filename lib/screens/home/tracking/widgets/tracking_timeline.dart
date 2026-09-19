import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/tracking_tokens.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/tracking/tracking_controller.dart';

/// Timeline رأسي 4 مراحل — تصميم SSOT.
class TrackingVerticalTimeline extends StatelessWidget {
  const TrackingVerticalTimeline({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final active = TrackingTimelineData.activeIndex(order.status);
    if (active < 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'تم إلغاء الطلب',
          style: CartTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: TrackingTokens.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(4, (i) {
        final done = i < active || order.status == OrderStatus.delivered;
        final current = i == active && order.status != OrderStatus.delivered;
        final pending = i > active;
        final time = TrackingTimelineData.stepTime(order, i);
        final subtitle = TrackingTimelineData.stepSubtitle(order, i, active);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    _TimelineDot(done: done, current: current, pending: pending),
                    if (i < 3)
                      Expanded(
                        child: CustomPaint(
                          size: const Size(2, double.infinity),
                          painter: _TimelineLinePainter(
                            color: done || current
                                ? TrackingTokens.timelineDone
                                : TrackingTokens.timelinePending,
                            dashed: current || pending,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < 3 ? 18 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              TrackingTimelineData.titles[i],
                              style: CartTypography.style(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: pending
                                    ? TrackingTokens.textMuted
                                    : current
                                        ? TrackingTokens.accent
                                        : TrackingTokens.textPrimary,
                              ),
                            ),
                          ),
                          if (time != null && !pending)
                            Text(
                              TrackingTimelineData.formatClock(time),
                              style: CartTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TrackingTokens.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (current || (pending && i == 3)) ...[
                        const SizedBox(height: 3),
                        Text(
                          current
                              ? subtitle
                              : TrackingTimelineData.etaArrivalLabel(
                                  order.etaMinutes > 0 ? order.etaMinutes : 15,
                                ),
                          style: CartTypography.style(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TrackingTokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.done,
    required this.current,
    required this.pending,
  });

  final bool done;
  final bool current;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    if (done && !current) {
      return Container(
        width: TrackingTokens.timelineDot,
        height: TrackingTokens.timelineDot,
        decoration: const BoxDecoration(
          color: TrackingTokens.timelineDone,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }
    if (current) {
      return Container(
        width: TrackingTokens.timelineDot,
        height: TrackingTokens.timelineDot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: TrackingTokens.timelineDone, width: 3),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: TrackingTokens.timelineDone,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: TrackingTokens.timelineDot,
      height: TrackingTokens.timelineDot,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TrackingTokens.timelinePending, width: 2),
      ),
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  _TimelineLinePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final x = size.width / 2;
    if (!dashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    const dash = 5.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}
