import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';

/// إجراءات الطلبات المكتملة — إعادة الطلب فقط.
class OrderCompletedActions extends StatelessWidget {
  const OrderCompletedActions({
    super.key,
    required this.order,
    required this.onReorder,
  });

  final Order order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'إعادة الطلب',
            icon: Icons.refresh_rounded,
            filled: true,
            onTap: onReorder,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.filled;
    final fg = filled ? Colors.white : OrdersTokens.accentText;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? OrdersTokens.pressScale : 1,
          duration: OrdersTokens.motionFast,
          child: Container(
            height: OrdersTokens.touchTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? OrdersTokens.ctaBackground : Colors.white,
              borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
              border: filled
                  ? null
                  : Border.all(color: OrdersTokens.accentText, width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 17, color: fg),
                const SizedBox(width: OrdersTokens.spaceSm),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CartTypography.style(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
