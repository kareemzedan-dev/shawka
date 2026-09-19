import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

class CartOrderNoteField extends StatelessWidget {
  const CartOrderNoteField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hint,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: CartTypography.style(
          fontSize: CartTokens.bodySize,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: CartTypography.style(
            fontSize: CartTokens.bodySize,
            color: AppColors.textHint,
          ),
          filled: true,
          fillColor: CartTokens.noteFill,
          prefixIcon: const Icon(
            Icons.edit_outlined,
            color: AppColors.textHint,
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CartTokens.spaceXl,
            vertical: CartTokens.spaceXl,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CartTokens.radiusMd),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class CartCouponCard extends StatelessWidget {
  const CartCouponCard({
    super.key,
    required this.title,
    required this.applyLabel,
    required this.controller,
    required this.busy,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  final String title;
  final String applyLabel;
  final TextEditingController controller;
  final bool busy;
  final String? appliedCode;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final applied = appliedCode != null && appliedCode!.isNotEmpty;
    return Semantics(
      container: true,
      label: applied ? 'كوبون مطبّق $appliedCode' : 'إدخال كوبون خصم',
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: CartTokens.dashedBorder,
          radius: CartTokens.radiusLg,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CartTokens.spaceLg,
            vertical: CartTokens.spaceMd,
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: AppColors.primary),
              const SizedBox(width: CartTokens.spaceSm),
              Expanded(
                child: applied
                    ? Text(
                        appliedCode!,
                        style: CartTypography.style(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : TextField(
                        controller: controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onApply(),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: title,
                          hintStyle: CartTypography.style(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        style: CartTypography.style(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
              const SizedBox(width: CartTokens.spaceSm),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CartTokens.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(CartTokens.radiusSm),
                  onTap: busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          if (applied) {
                            onRemove();
                          } else {
                            onApply();
                          }
                        },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: CartTokens.touchTarget,
                      minWidth: 64,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CartTokens.spaceXl,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(CartTokens.radiusSm),
                        border: Border.all(color: CartTokens.couponActionBorder),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: CartTokens.couponBusySize,
                              height: CartTokens.couponBusySize,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Semantics(
                              button: true,
                              label: applied ? 'إزالة الكوبون' : applyLabel,
                              child: Text(
                                applied ? 'إزالة' : applyLabel,
                                style: CartTypography.style(
                                  fontSize: CartTokens.captionSize,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
