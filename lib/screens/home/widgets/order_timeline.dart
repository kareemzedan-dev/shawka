import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/order.dart';

/// Timeline steps for active order tracking (UI only).
abstract final class OrderTimelineSteps {
  static const labels = [
    'تم استلام الطلب',
    'قيد المراجعة',
    'جاري التحضير',
    'جاهز للاستلام',
    'خرج للتوصيل',
    'تم التسليم',
  ];

  static int activeStepIndex(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 1,
      OrderStatus.preparing => 2,
      OrderStatus.readyForPickup => 3,
      OrderStatus.onTheWay => 4,
      OrderStatus.delivered => 5,
      OrderStatus.cancelled => 0,
    }.clamp(0, labels.length - 1);
  }
}

/// Compact 4-step timeline for order cards (matches orders mockup).
class OrderCompactCardTimeline extends StatelessWidget {
  const OrderCompactCardTimeline({
    super.key,
    required this.status,
  });

  final OrderStatus status;

  static const _labels = [
    'تم استلام الطلب',
    'قيد التحضير الآن',
    'خرج للتوصيل',
    'تم التسليم',
  ];

  static int _currentIndex(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 1,
      OrderStatus.preparing => 1,
      OrderStatus.readyForPickup => 2,
      OrderStatus.onTheWay => 2,
      OrderStatus.delivered => 4,
      OrderStatus.cancelled => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(status);
    final allDone = status == OrderStatus.delivered;

    return Column(
      children: List.generate(_labels.length, (index) {
        final isDone = allDone || index < current;
        final isCurrent = !allDone && index == current;
        final isFuture = !isDone && !isCurrent;
        final isLast = index == _labels.length - 1;

        return _CompactTimelineRow(
          label: _labels[index],
          isDone: isDone,
          isCurrent: isCurrent,
          isFuture: isFuture,
          showConnector: !isLast,
        );
      }),
    );
  }
}

class _CompactTimelineRow extends StatelessWidget {
  const _CompactTimelineRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isFuture,
    required this.showConnector,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isFuture;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone || isCurrent
        ? AppColors.primary
        : const Color(0xFFD1D5DB);
    final lineColor = isDone
        ? AppColors.primary.withValues(alpha: 0.55)
        : const Color(0xFFE5E7EB);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.primary
                        : isCurrent
                            ? Colors.white
                            : const Color(0xFFE5E7EB),
                    border: Border.all(
                      color: dotColor,
                      width: isCurrent ? 2.5 : 0,
                    ),
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_rounded
                        : isCurrent
                            ? Icons.circle
                            : null,
                    size: isDone ? 14 : (isCurrent ? 10 : 0),
                    color: isDone
                        ? Colors.white
                        : isCurrent
                            ? AppColors.primary
                            : null,
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 1,
                bottom: showConnector ? 14 : 0,
              ),
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: isCurrent ? 14 : 13,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent
                      ? const Color(0xFF111827)
                      : isDone
                          ? AppColors.primary
                          : const Color(0xFF9CA3AF),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical progress timeline for an order.
class OrderProgressTimeline extends StatelessWidget {
  const OrderProgressTimeline({
    super.key,
    required this.status,
    required this.palette,
    this.compact = false,
  });

  final OrderStatus status;
  final AppPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = OrderTimelineSteps.activeStepIndex(status);
    final allDone = status == OrderStatus.delivered;

    return Column(
      children: List.generate(OrderTimelineSteps.labels.length, (index) {
        final isDone =
            allDone || index == 0 || index < current;
        final isCurrent = !allDone && index == current;
        final isFuture = !isDone && !isCurrent;
        final isLast = index == OrderTimelineSteps.labels.length - 1;

        return _TimelineStepRow(
          palette: palette,
          label: OrderTimelineSteps.labels[index],
          isDone: isDone,
          isCurrent: isCurrent,
          isFuture: isFuture,
          showConnector: !isLast,
          compact: compact,
        );
      }),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.palette,
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isFuture,
    required this.showConnector,
    required this.compact,
  });

  final AppPalette palette;
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isFuture;
  final bool showConnector;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : palette.textHint.withValues(alpha: 0.45);
    final lineColor = isDone
        ? AppColors.success.withValues(alpha: 0.45)
        : palette.border.withValues(alpha: isFuture ? 0.5 : 0.85);

    final labelStyle = GoogleFonts.cairo(
      fontSize: isCurrent
          ? (compact ? 13.5 : 14.5)
          : isDone
              ? (compact ? 12 : 13)
              : (compact ? 11.5 : 12),
      fontWeight: isCurrent
          ? FontWeight.w800
          : isDone
              ? FontWeight.w700
              : FontWeight.w500,
      color: isCurrent
          ? AppColors.primary
          : isDone
              ? AppColors.success
              : palette.textHint.withValues(alpha: palette.isDark ? 0.65 : 0.55),
      height: 1.2,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 24 : 28,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: HomeTheme.animStandard,
                  width: compact ? 20 : 24,
                  height: compact ? 20 : 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.14)
                        : isCurrent
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : palette.surfaceMuted.withValues(alpha: 0.8),
                    border: Border.all(
                      color: dotColor,
                      width: isCurrent ? 2.2 : 1.1,
                    ),
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_rounded
                        : isCurrent
                            ? Icons.radio_button_checked_rounded
                            : Icons.circle_outlined,
                    size: isDone ? 13 : (isCurrent ? 12 : 9),
                    color: dotColor,
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: compact ? 1 : 3,
                bottom: showConnector ? (compact ? 6 : 10) : 0,
              ),
              child: AnimatedDefaultTextStyle(
                duration: HomeTheme.animStandard,
                style: labelStyle,
                child: Text(label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium status badge with emoji (orders UI).
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    this.large = false,
    this.compact = false,
  });

  final OrderStatus status;
  final bool large;
  final bool compact;

  static String displayLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => '🟠 قيد المراجعة',
        OrderStatus.preparing => '🔵 جاري التحضير',
        OrderStatus.readyForPickup => '🟢 جاهز للاستلام',
        OrderStatus.onTheWay => '🟣 خرج للتوصيل',
        OrderStatus.delivered => '✅ تم التسليم',
        OrderStatus.cancelled => '🔴 ملغي',
      };

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : (large ? 12 : 10),
        vertical: compact ? 4 : (large ? 7 : 5),
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: palette.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status.color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        displayLabel(status),
        style: GoogleFonts.cairo(
          fontSize: compact ? 10.5 : (large ? 12.5 : 11),
          fontWeight: FontWeight.w800,
          color: status.color,
          height: 1.1,
        ),
      ),
    );
  }
}
