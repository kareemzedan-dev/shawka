import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';

/// زر تفاصيل الطلب للطلبات النشطة.
class OrderTrackButton extends StatefulWidget {
  const OrderTrackButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<OrderTrackButton> createState() => _OrderTrackButtonState();
}

class _OrderTrackButtonState extends State<OrderTrackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'تفاصيل الطلب',
      excludeSemantics: true,
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
          curve: OrdersTokens.curveStandard,
          child: Container(
            height: OrdersTokens.trackButtonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OrdersTokens.ctaBackground,
              borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
              boxShadow: OrdersTokens.trackButtonShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: OrdersTokens.spaceSm),
                Text(
                  'تفاصيل الطلب',
                  style: CartTypography.style(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
