import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';

/// منطق نقي للوقت المتوقّع — قابل للاختبار دون واجهة.
abstract final class OrderEtaInfo {
  /// يُعرض عندما يكون الطلب نشطاً وله وقت متوقّع موجب.
  static bool shouldShow(Order order) =>
      order.status.isActive && order.etaMinutes > 0;

  /// متأخّر إذا تجاوز الوقت الحالي (createdAt + etaMinutes).
  static bool isDelayed(Order order, {DateTime? now}) {
    if (order.etaMinutes <= 0) return false;
    final expected = order.createdAt.add(Duration(minutes: order.etaMinutes));
    return (now ?? DateTime.now()).isAfter(expected);
  }
}

/// بطاقة الوقت المتوقّع للوصول + الإجمالي (رمادي فاتح).
class OrderEtaCard extends StatelessWidget {
  const OrderEtaCard({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final delayed = OrderEtaInfo.isDelayed(order);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OrdersTokens.space2xl,
        vertical: OrdersTokens.spaceLg,
      ),
      decoration: BoxDecoration(
        color: OrdersTokens.etaCardFill,
        borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
        border: Border.all(color: OrdersTokens.etaCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // يمين (RTL): الوقت المتوقّع.
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: OrdersTokens.textSecondary,
                    ),
                    const SizedBox(width: OrdersTokens.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الوقت المتوقع للوصول',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: OrdersTokens.etaTitleSize,
                              fontWeight: FontWeight.w600,
                              color: OrdersTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.etaMinutes} دقيقة',
                            style: CartTypography.style(
                              fontSize: OrdersTokens.etaValueSize,
                              fontWeight: FontWeight.w800,
                              color: OrdersTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OrdersTokens.spaceMd),
              // يسار (RTL): الإجمالي.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الإجمالي',
                    style: CartTypography.style(
                      fontSize: OrdersTokens.etaTitleSize,
                      fontWeight: FontWeight.w600,
                      color: OrdersTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.grandTotal.toStringAsFixed(0)} ج.م',
                    style: CartTypography.style(
                      fontSize: OrdersTokens.etaValueSize,
                      fontWeight: FontWeight.w800,
                      color: OrdersTokens.accentText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (delayed) ...[
            const SizedBox(height: OrdersTokens.spaceMd),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: OrdersTokens.accentText,
                ),
                const SizedBox(width: OrdersTokens.spaceXs),
                Expanded(
                  child: Text(
                    'الطلب يستغرق وقتاً أطول من المتوقع — نعتذر عن التأخير',
                    style: CartTypography.style(
                      fontSize: OrdersTokens.metaSize,
                      fontWeight: FontWeight.w700,
                      color: OrdersTokens.accentText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
