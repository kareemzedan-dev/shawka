import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';

/// شريط سفلي ثابت: أيقونة حقيبة + «إضافة إلى السلة» + الإجمالي + سهم.
class ProductAddToCartBar extends StatefulWidget {
  const ProductAddToCartBar({
    super.key,
    required this.state,
    required this.total,
    required this.unavailableReason,
    required this.onAdd,
  });

  final ProductCtaState state;
  final double total;
  final String? unavailableReason;
  final VoidCallback onAdd;

  @override
  State<ProductAddToCartBar> createState() => _ProductAddToCartBarState();
}

class _ProductAddToCartBarState extends State<ProductAddToCartBar> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  bool get _enabled =>
      widget.unavailableReason == null &&
      widget.state != ProductCtaState.loading &&
      widget.state != ProductCtaState.disabled;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final loading = widget.state == ProductCtaState.loading;
    final success = widget.state == ProductCtaState.success;

    final label = widget.unavailableReason ??
        (success ? 'تمت الإضافة' : 'إضافة إلى السلة');

    return Container(
      padding: EdgeInsets.fromLTRB(
        ProductTokens.pagePadding,
        ProductTokens.spaceLg,
        ProductTokens.pagePadding,
        ProductTokens.spaceLg + bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: ProductTokens.ctaBarShadow,
      ),
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: '$label ${widget.total.toStringAsFixed(0)} جنيه',
        child: Listener(
          onPointerDown: _enabled ? (_) => _setPressed(true) : null,
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? ProductTokens.ctaPressScale : 1,
            duration: ProductTokens.motionFast,
            curve: ProductTokens.curveStandard,
            child: FilledButton(
              onPressed: _enabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      widget.onAdd();
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: success
                    ? ProductTokens.discountBadgeText
                    : ProductTokens.ctaBackground,
                disabledBackgroundColor: const Color(0xFFCBD2DB),
                minimumSize: const Size.fromHeight(ProductTokens.ctaHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ProductTokens.radiusLg),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : _CtaContent(
                      label: label,
                      total: widget.total,
                      success: success,
                      showTotal: widget.unavailableReason == null && !success,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaContent extends StatelessWidget {
  const _CtaContent({
    required this.label,
    required this.total,
    required this.success,
    required this.showTotal,
  });

  final String label;
  final double total;
  final bool success;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          success
              ? Icons.check_circle_rounded
              : Icons.shopping_bag_outlined,
          size: 22,
          color: Colors.white,
        ),
        const SizedBox(width: ProductTokens.spaceMd),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CartTypography.style(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        if (showTotal) ...[
          Text(
            '${total.toStringAsFixed(0)} ج.م',
            style: CartTypography.style(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: ProductTokens.spaceSm),
          Container(
            width: ProductTokens.ctaChevron,
            height: ProductTokens.ctaChevron,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
