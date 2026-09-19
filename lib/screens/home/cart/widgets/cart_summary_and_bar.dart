import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

class CartPriceSummary extends StatelessWidget {
  const CartPriceSummary({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.subtotalLabel,
    required this.discountLabel,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final String subtotalLabel;
  final String discountLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '$subtotalLabel $itemCount أصناف ${subtotal.toStringAsFixed(2)} جنيه'
          '${discount > 0 ? '. $discountLabel ${discount.toStringAsFixed(2)} جنيه' : ''}',
      child: Column(
        children: [
          _row(
            '$subtotalLabel ($itemCount أصناف)',
            '${subtotal.toStringAsFixed(2)} ج.م',
          ),
          if (discount > 0) ...[
            const SizedBox(height: CartTokens.spaceSm),
            _row(
              discountLabel,
              '- ${discount.toStringAsFixed(2)} ج.م',
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    final color = emphasize ? CartTokens.accentText : AppColors.textPrimary;
    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: CartTypography.style(
                fontSize: CartTokens.bodySize,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Text(
            value,
            style: CartTypography.style(
              fontSize: CartTokens.bodySize,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class CartContinueBar extends StatelessWidget {
  const CartContinueBar({
    super.key,
    required this.totalLabel,
    required this.total,
    required this.ctaLabel,
    required this.onContinue,
    this.enabled = true,
    /// عند التضمين فوق [AppBottomNav] لا نضيف inset الجهاز مرة ثانية.
    this.embedAboveBottomNav = true,
  });

  final String totalLabel;
  final double total;
  final String ctaLabel;
  final VoidCallback? onContinue;
  final bool enabled;
  final bool embedAboveBottomNav;

  @override
  Widget build(BuildContext context) {
    final bottom = embedAboveBottomNav
        ? CartTokens.spaceLg
        : MediaQuery.paddingOf(context).bottom + CartTokens.spaceLg;
    return Semantics(
      container: true,
      label: '$totalLabel ${total.toStringAsFixed(2)} جنيه',
      child: Container(
        padding: EdgeInsets.fromLTRB(
          CartTokens.pagePadding,
          CartTokens.spaceLg,
          CartTokens.pagePadding,
          bottom,
        ),
        decoration: BoxDecoration(
          color: context.palette.surface,
          boxShadow: CartTokens.continueBarShadow,
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      totalLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'الإجمالي ${total.toStringAsFixed(2)} جنيه',
                    child: Text(
                      '${total.toStringAsFixed(2)} ج.م',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: CartTokens.totalSize,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CartTokens.spaceXl),
            Expanded(
              child: _AnimatedContinueButton(
                enabled: enabled && onContinue != null,
                label: ctaLabel,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedContinueButton extends StatefulWidget {
  const _AnimatedContinueButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_AnimatedContinueButton> createState() =>
      _AnimatedContinueButtonState();
}

class _AnimatedContinueButtonState extends State<_AnimatedContinueButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: Listener(
        onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? CartTokens.continuePressScale : 1,
          duration: CartTokens.motionFast,
          curve: CartTokens.curveStandard,
          child: FilledButton(
            onPressed: !widget.enabled || widget.onPressed == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onPressed!();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: CartTokens.ctaBackground,
              disabledBackgroundColor:
                  CartTokens.ctaBackground.withValues(alpha: 0.4),
              minimumSize: const Size(0, CartTokens.continueButtonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CartTokens.radiusLg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: CartTypography.style(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: CartTokens.spaceMd),
                Container(
                  width: CartTokens.continueArrow,
                  height: CartTokens.continueArrow,
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
            ),
          ),
        ),
      ),
    );
  }
}
