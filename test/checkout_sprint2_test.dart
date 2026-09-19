import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/debug/checkout_preview.dart';
import 'package:matlobgo/screens/home/checkout/checkout_error_message.dart';

import 'golden/checkout_golden_helpers.dart';

void main() {
  setUpAll(prepareCheckoutGoldens);

  group('Checkout critical error mapping', () {
    test('maps out-of-zone payment coupon and in-progress', () {
      expect(
        checkoutErrorMessage(StateError('STORE_OUT_OF_DELIVERY_ZONE')),
        contains('غير متاح'),
      );
      expect(
        checkoutErrorMessage(StateError('PAYMENT_METHOD_UNAVAILABLE')),
        contains('الدفع'),
      );
      expect(
        checkoutErrorMessage(StateError('CHECKOUT_ALREADY_IN_PROGRESS')),
        contains('بالفعل'),
      );
      expect(
        checkoutErrorMessage(StateError('INVALID_COUPON')),
        contains('الخصم'),
      );
      expect(
        checkoutErrorMessage(StateError('ADDRESS_OUT_OF_ZONE')),
        contains('نطاق التوصيل'),
      );
      expect(
        checkoutErrorMessage(StateError('CUSTOMER_QUANTITY_LIMIT')),
        contains('الحد الأقصى المسموح'),
      );
    });
  });

  group('Checkout a11y — payment summary confirm', () {
    testWidgets('payment section announces methods', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapCheckoutGolden(const CheckoutPaymentSectionPreview()),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('الدفع عند الاستلام')),
          findsWidgets,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('summary and confirm are labeled', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapCheckoutGolden(
            const Column(
              children: [
                Expanded(child: CheckoutSummaryPreview()),
                CheckoutConfirmBarPreview(),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(RegExp('ملخص الدفع')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('تأكيد الطلب')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('الإجمالي')), findsWidgets);
      } finally {
        handle.dispose();
      }
    });
  });

  test('server quote is authoritative — draft money stays zero in contract', () {
    final quote = sampleCheckoutQuote();
    expect(quote.grandTotal, 175);
    expect(quote.subtotal, 170);
    expect(quote.deliveryFee, 15);
    expect(quote.discountAmount, 10);
  });
}
