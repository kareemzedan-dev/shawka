import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';

/// خط زمني أفقي من 4 خطوات لبطاقة الطلب — مطابق للتصميم.
///
/// الخطوات: تم الاستلام → قيد التحضير → خرج للتوصيل → تم التسليم.
/// الخطوة الحالية لها توهّج + لون accent، المكتملة ممتلئة، القادمة باهتة.
class OrderHorizontalTimeline extends StatelessWidget {
  const OrderHorizontalTimeline({
    super.key,
    required this.status,
  });

  final OrderStatus status;

  static const labels = <String>[
    'تم الاستلام',
    'قيد التحضير',
    'خرج للتوصيل',
    'تم التسليم',
  ];

  static const _icons = <IconData>[
    Icons.receipt_long_rounded,
    Icons.storefront_rounded,
    Icons.delivery_dining_rounded,
    Icons.check_circle_rounded,
  ];

  /// خريطة الحالة → مؤشّر الخطوة الحالية (تصميم SSOT):
  /// pending→0، preparing→1، readyForPickup→2، onTheWay→2، delivered→3 (الكل مكتمل).
  /// cancelled→-1 (يُخفى الخط الزمني).
  static int stepIndexFor(OrderStatus status) => switch (status) {
        OrderStatus.pending => 0,
        OrderStatus.preparing => 1,
        OrderStatus.readyForPickup => 2,
        OrderStatus.onTheWay => 2,
        OrderStatus.delivered => 3,
        OrderStatus.cancelled => -1,
      };

  static bool isAllDone(OrderStatus status) => status == OrderStatus.delivered;

  @override
  Widget build(BuildContext context) {
    final current = stepIndexFor(status);
    final allDone = isAllDone(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length, (index) {
        final isDone = allDone || index < current;
        final isCurrent = !allDone && index == current;
        final isLast = index == labels.length - 1;

        return Expanded(
          child: _TimelineStep(
            label: labels[index],
            icon: _icons[index],
            isDone: isDone,
            isCurrent: isCurrent,
            showConnectorAfter: !isLast,
            connectorDone: allDone || index < current,
          ),
        );
      }),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.showConnectorAfter,
    required this.connectorDone,
  });

  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool showConnectorAfter;
  final bool connectorDone;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isDone
        ? OrdersTokens.timelineDone
        : isCurrent
            ? OrdersTokens.timelineCurrent
            : OrdersTokens.timelineFuture;
    final bool filled = isDone || isCurrent;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Node(
              icon: icon,
              color: dotColor,
              filled: filled,
              glow: isCurrent,
            ),
            if (showConnectorAfter)
              Expanded(
                child: Container(
                  height: 2.5,
                  margin: const EdgeInsets.symmetric(
                    horizontal: OrdersTokens.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: connectorDone
                        ? OrdersTokens.timelineDone.withValues(alpha: 0.6)
                        : OrdersTokens.timelineTrack,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: OrdersTokens.spaceSm),
        Padding(
          padding: const EdgeInsets.only(right: OrdersTokens.spaceXs),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CartTypography.style(
              fontSize: OrdersTokens.timelineLabelSize,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: filled
                  ? OrdersTokens.timelineDone
                  : OrdersTokens.textMuted,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.icon,
    required this.color,
    required this.filled,
    required this.glow,
  });

  final IconData icon;
  final Color color;
  final bool filled;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: OrdersTokens.timelineDot,
      height: OrdersTokens.timelineDot,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.white,
        border: Border.all(
          color: filled ? color : OrdersTokens.timelineFuture,
          width: glow ? 2.4 : 1.4,
        ),
        boxShadow: glow ? OrdersTokens.timelineGlow : null,
      ),
      child: Icon(
        icon,
        size: OrdersTokens.timelineIcon,
        color: filled ? Colors.white : OrdersTokens.timelineFuture,
      ),
    );
  }
}
