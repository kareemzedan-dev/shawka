import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';

class CheckoutConfirmBar extends StatelessWidget {
  const CheckoutConfirmBar({
    super.key,
    required this.palette,
    required this.grandTotal,
    required this.loading,
    required this.bottomPadding,
    required this.label,
    required this.totalLabel,
    required this.onConfirm,
  });

  final AppPalette palette;
  final double grandTotal;
  final bool loading;
  final double bottomPadding;
  final String label;
  final String totalLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$totalLabel ${grandTotal.toStringAsFixed(0)} جنيه',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          boxShadow: CheckoutTokens.confirmBarShadow,
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CheckoutTokens.pagePadding + 2,
              13,
              CheckoutTokens.pagePadding + 2,
              13,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _AnimatedConfirmButton(
                    enabled: onConfirm != null && !loading,
                    loading: loading,
                    label: label,
                    onPressed: onConfirm,
                  ),
                ),
                const SizedBox(width: CheckoutTokens.spaceXl),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          totalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CartTypography.style(
                            fontSize: 11.5,
                            color: palette.textHint,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'الإجمالي ${grandTotal.toStringAsFixed(0)} جنيه',
                        child: Text(
                          '${grandTotal.toStringAsFixed(0)} ج.م',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CartTypography.style(
                            fontSize: 20,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
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

class _AnimatedConfirmButton extends StatefulWidget {
  const _AnimatedConfirmButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_AnimatedConfirmButton> createState() => _AnimatedConfirmButtonState();
}

class _AnimatedConfirmButtonState extends State<_AnimatedConfirmButton> {
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
          scale: _pressed ? CheckoutTokens.confirmPressScale : 1,
          duration: CheckoutTokens.motionFast,
          curve: CheckoutTokens.curveStandard,
          child: SizedBox(
            height: CheckoutTokens.confirmButtonHeight + 2,
            child: FilledButton(
              onPressed: !widget.enabled || widget.onPressed == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onPressed!();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: CheckoutTokens.ctaBackground,
                disabledBackgroundColor:
                    CheckoutTokens.ctaBackground.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CheckoutTokens.radiusMd),
                ),
              ),
              child: widget.loading
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 20),
                        const SizedBox(width: CheckoutTokens.spaceSm),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
