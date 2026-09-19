import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';

/// رابط «تفاصيل الطلب» مع chevron — يوسّع لعرض التفاصيل.
/// البناء كسول: محتوى التفاصيل يُبنى فقط عند [expanded].
class OrderExpandableDetails extends StatelessWidget {
  const OrderExpandableDetails({
    super.key,
    required this.order,
    required this.expanded,
    required this.onToggle,
  });

  final Order order;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          label: 'تفاصيل الطلب',
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(OrdersTokens.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: OrdersTokens.spaceMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تفاصيل الطلب',
                    style: CartTypography.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: OrdersTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: OrdersTokens.spaceXs),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: OrdersTokens.motionStandard,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: OrdersTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: OrdersTokens.motionStandard,
          curve: OrdersTokens.curveStandard,
          alignment: Alignment.topCenter,
          child: expanded
              ? _OrderDetailsBody(order: order)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _OrderDetailsBody extends StatelessWidget {
  const _OrderDetailsBody({required this.order});

  final Order order;

  String _formatDateFull(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} · $h:$m';
  }

  String _paymentLabel(String method) => switch (method) {
        'card' => 'بطاقة بنكية',
        'wallet' => 'محفظة إلكترونية',
        _ => 'الدفع عند الاستلام',
      };

  @override
  Widget build(BuildContext context) {
    final address = order.address?.trim();
    final deliveryLine = (address != null && address.isNotEmpty)
        ? address
        : (order.governorate.isNotEmpty ? order.governorate : null);
    final reason = order.deliveryRejectReason?.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: OrdersTokens.spaceSm),
      padding: const EdgeInsets.all(OrdersTokens.spaceLg),
      decoration: BoxDecoration(
        color: OrdersTokens.detailsFill,
        borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.status == OrderStatus.cancelled &&
              reason != null &&
              reason.isNotEmpty)
            _DetailLine(
              icon: Icons.info_outline_rounded,
              label: 'سبب الإلغاء',
              value: reason,
              emphasize: true,
            ),
          if (order.itemsSummary.trim().isNotEmpty)
            _DetailLine(
              icon: Icons.inventory_2_outlined,
              label: 'المنتجات',
              value: order.itemsSummary,
            ),
          _DetailLine(
            icon: Icons.schedule_rounded,
            label: 'وقت الطلب',
            value: _formatDateFull(order.createdAt),
          ),
          if (deliveryLine != null)
            _DetailLine(
              icon: Icons.location_on_outlined,
              label: 'عنوان التوصيل',
              value: deliveryLine,
            ),
          if (order.phone != null && order.phone!.trim().isNotEmpty)
            _DetailLine(
              icon: Icons.phone_outlined,
              label: 'الهاتف',
              value: order.phone!,
            ),
          _DetailLine(
            icon: Icons.payments_outlined,
            label: 'وسيلة الدفع',
            value: _paymentLabel(order.paymentMethod),
          ),
          const Divider(height: OrdersTokens.space2xl),
          if (order.deliveryFee > 0)
            _AmountLine(
              label: 'رسوم التوصيل',
              value: '${order.deliveryFee.toStringAsFixed(0)} ج.م',
            ),
          if (order.serviceFee > 0)
            _AmountLine(
              label: 'رسوم الخدمة',
              value: '${order.serviceFee.toStringAsFixed(0)} ج.م',
            ),
          if (order.taxes > 0)
            _AmountLine(
              label: 'الضرائب',
              value: '${order.taxes.toStringAsFixed(0)} ج.م',
            ),
          if (order.discountAmount > 0)
            _AmountLine(
              label: 'الخصم',
              value: '- ${order.discountAmount.toStringAsFixed(0)} ج.م',
              valueColor: OrdersTokens.timelineDone,
            ),
          _AmountLine(
            label: 'الإجمالي',
            value: '${order.grandTotal.toStringAsFixed(0)} ج.م',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OrdersTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: emphasize ? OrdersTokens.accentText : OrdersTokens.textMuted,
          ),
          const SizedBox(width: OrdersTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CartTypography.style(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: OrdersTokens.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: CartTypography.style(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: emphasize
                        ? OrdersTokens.accentText
                        : OrdersTokens.textPrimary,
                    height: 1.35,
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

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OrdersTokens.spaceSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CartTypography.style(
              fontSize: emphasize ? 13.5 : 12.5,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize
                  ? OrdersTokens.textPrimary
                  : OrdersTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: CartTypography.style(
              fontSize: emphasize ? 14.5 : 12.5,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ??
                  (emphasize
                      ? OrdersTokens.accentText
                      : OrdersTokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
