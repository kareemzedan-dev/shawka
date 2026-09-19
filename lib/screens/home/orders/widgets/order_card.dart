import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_completed_actions.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_eta_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_expandable_details.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_horizontal_timeline.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_products_preview.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_restaurant_header.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_track_button.dart';

/// بطاقة الطلب البيضاء المرفوعة — تكوين رفيع لمكوّنات الطلب.
///
/// الاختلافات حسب الحالة تُدار هنا (لا منطق أعمال):
/// - نشطة: خط زمني + بطاقة ETA + زر تتبّع.
/// - مكتملة: بدون خط زمني/ETA/تتبّع + إجراءات (إعادة/تقييم).
/// - ملغية: شارة الحالة فقط + تفاصيل قابلة للتوسيع.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.expanded,
    required this.onToggleExpand,
    required this.onTrack,
    required this.onReorder,
  });

  final Order order;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final isActive = order.status.isActive;
    final isCancelled = order.status == OrderStatus.cancelled;
    final isCompleted = order.status == OrderStatus.delivered;
    final showTimeline = isActive;
    final showEta = OrderEtaInfo.shouldShow(order);

    return Container(
      decoration: BoxDecoration(
        color: OrdersTokens.cardBackground,
        borderRadius: BorderRadius.circular(OrdersTokens.cardRadius),
        border: Border.all(color: OrdersTokens.cardBorder),
        boxShadow: OrdersTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(OrdersTokens.space2xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: OrderRestaurantHeader(order: order)),
              if (isCancelled) ...[
                const SizedBox(width: OrdersTokens.spaceSm),
                const _CancelledBadge(),
              ],
            ],
          ),
          if (showTimeline) ...[
            const SizedBox(height: OrdersTokens.space2xl),
            OrderHorizontalTimeline(status: order.status),
          ],
          if (showEta) ...[
            const SizedBox(height: OrdersTokens.space2xl),
            OrderEtaCard(order: order),
          ],
          const SizedBox(height: OrdersTokens.spaceLg),
          OrderProductsPreview(order: order),
          // الطلبات المكتملة تعرض الإجمالي (بدل بطاقة ETA النشطة).
          if (isCompleted) ...[
            const SizedBox(height: OrdersTokens.spaceLg),
            _TotalLine(order: order),
          ],
          if (showTimeline) ...[
            const SizedBox(height: OrdersTokens.spaceLg),
            OrderTrackButton(onTap: onTrack),
          ],
          if (isCompleted) ...[
            const SizedBox(height: OrdersTokens.spaceLg),
            OrderCompletedActions(
              order: order,
              onReorder: onReorder,
            ),
          ],
          const SizedBox(height: OrdersTokens.spaceXs),
          OrderExpandableDetails(
            order: order,
            expanded: expanded,
            onToggle: onToggleExpand,
          ),
        ],
      ),
    );
  }
}

/// سطر الإجمالي للطلبات المكتملة — السعر بلون accentText (WCAG على أبيض).
class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'الإجمالي ${order.grandTotal.toStringAsFixed(0)} جنيه',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الإجمالي',
            style: CartTypography.style(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: OrdersTokens.textSecondary,
            ),
          ),
          Text(
            '${order.grandTotal.toStringAsFixed(0)} ج.م',
            style: CartTypography.style(
              fontSize: OrdersTokens.priceSize,
              fontWeight: FontWeight.w800,
              color: OrdersTokens.accentText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();

  @override
  Widget build(BuildContext context) {
    final color = OrderStatus.cancelled.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OrdersTokens.spaceMd,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(OrdersTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        'ملغي',
        style: CartTypography.style(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
