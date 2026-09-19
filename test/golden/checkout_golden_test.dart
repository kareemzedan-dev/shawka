import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/debug/checkout_preview.dart';

import 'checkout_golden_helpers.dart';

void main() {
  setUpAll(prepareCheckoutGoldens);

  testWidgets('golden checkout full screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrapCheckoutGolden(const CheckoutPreviewScreen()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CheckoutPreviewScreen),
      matchesGoldenFile('goldens/checkout_full_screen.png'),
    );
  });

  testWidgets('golden checkout payment section', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrapCheckoutGolden(
        const CheckoutPaymentSectionPreview(),
        size: const Size(390, 280),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CheckoutPaymentSectionPreview),
      matchesGoldenFile('goldens/checkout_payment_section.png'),
    );
  });

  testWidgets('golden checkout summary', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrapCheckoutGolden(
        const CheckoutSummaryPreview(),
        size: const Size(390, 320),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CheckoutSummaryPreview),
      matchesGoldenFile('goldens/checkout_summary.png'),
    );
  });

  testWidgets('golden checkout continue bar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrapCheckoutGolden(
        const SizedBox(
          width: 390,
          child: CheckoutConfirmBarPreview(),
        ),
        size: const Size(390, 120),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CheckoutConfirmBarPreview),
      matchesGoldenFile('goldens/checkout_continue_bar.png'),
    );
  });
}
