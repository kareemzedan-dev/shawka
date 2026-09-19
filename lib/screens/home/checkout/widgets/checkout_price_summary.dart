import 'package:flutter/material.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_section.dart';

typedef CheckoutLabelResolver = String Function(String key, String fallback);

class CheckoutPriceSummary extends StatelessWidget {
  const CheckoutPriceSummary({
    super.key,
    required this.palette,
    required this.quote,
    required this.fallbackSubtotal,
    required this.label,
    required this.note,
    this.loading = false,
  });

  final AppPalette palette;
  final CheckoutQuote? quote;
  final double fallbackSubtotal;
  final CheckoutLabelResolver label;
  final String note;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: loading
          ? 'جارٍ حساب ملخص الدفع'
          : 'ملخص الدفع. الإجمالي الفرعي ${(quote?.subtotal ?? fallbackSubtotal).toStringAsFixed(0)} جنيه',
      child: CheckoutSurfaceCard(
        palette: palette,
        padding: const EdgeInsets.all(17),
        child: loading && quote == null
            ? const _SummarySkeleton()
            : Column(
                children: [
                  PriceRow(
                    label: label(CmsKeys.checkoutSubtotal, 'المجموع الفرعي'),
                    value:
                        '${(quote?.subtotal ?? fallbackSubtotal).toStringAsFixed(0)} ج.م',
                  ),
                  const SizedBox(height: CheckoutTokens.spaceMd + 1),
                  PriceRow(
                    label: label(CmsKeys.checkoutDeliveryFee, 'رسوم التوصيل'),
                    value: quote != null && quote!.deliveryFee == 0
                        ? 'مجاني'
                        : '${quote?.deliveryFee.toStringAsFixed(0) ?? '—'} ج.م',
                    valueColor: quote != null && quote!.deliveryFee == 0
                        ? AppColors.success
                        : null,
                  ),
                  if ((quote?.discountAmount ?? 0) > 0) ...[
                    const SizedBox(height: CheckoutTokens.spaceMd + 1),
                    PriceRow(
                      label:
                          '${label(CmsKeys.checkoutDiscount, 'الخصم')} (${quote!.couponCode})',
                      value: '- ${quote!.discountAmount.toStringAsFixed(0)} ج.م',
                      valueColor: CheckoutTokens.accentText,
                    ),
                  ],
                  if ((quote?.serviceFee ?? 0) > 0) ...[
                    const SizedBox(height: CheckoutTokens.spaceMd + 1),
                    PriceRow(
                      label: label(CmsKeys.checkoutServiceFee, 'رسوم الخدمة'),
                      value: '${quote!.serviceFee.toStringAsFixed(0)} ج.م',
                    ),
                  ],
                  if ((quote?.paymentFee ?? 0) > 0) ...[
                    const SizedBox(height: CheckoutTokens.spaceMd + 1),
                    PriceRow(
                      label: label(CmsKeys.checkoutPaymentFee, 'رسوم الدفع'),
                      value: '${quote!.paymentFee.toStringAsFixed(0)} ج.م',
                    ),
                  ],
                  if ((quote?.taxes ?? 0) > 0) ...[
                    const SizedBox(height: CheckoutTokens.spaceMd + 1),
                    PriceRow(
                      label: label(CmsKeys.checkoutTaxes, 'الضرائب'),
                      value: '${quote!.taxes.toStringAsFixed(0)} ج.م',
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: DashedDivider(),
                  ),
                  Text(
                    note,
                    style: CartTypography.style(
                      fontSize: 11.5,
                      color: palette.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar({double widthFactor = 1}) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: CheckoutTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(CheckoutTokens.radiusPill),
          ),
        ),
      );
    }

    return Column(
      children: [
        bar(),
        const SizedBox(height: CheckoutTokens.spaceLg),
        bar(widthFactor: 0.85),
        const SizedBox(height: CheckoutTokens.spaceLg),
        bar(widthFactor: 0.7),
        const SizedBox(height: CheckoutTokens.spaceXl),
        bar(widthFactor: 0.55),
      ],
    );
  }
}

class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: CartTypography.style(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.palette.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: CartTypography.style(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? context.palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(
        painter: DashedDividerPainter(context.palette.border),
      ),
    );
  }
}

class DashedDividerPainter extends CustomPainter {
  const DashedDividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
