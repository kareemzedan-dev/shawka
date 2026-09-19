import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/wcag_contrast.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_item_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_suggested_products.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_summary_and_bar.dart';

import 'golden/cart_golden_helpers.dart';

void main() {
  setUpAll(prepareCartGoldens);

  group('WCAG contrast — cart palette', () {
    final pairs = <CartContrastPair>[
      const CartContrastPair(
        id: 'navy_on_white',
        foreground: AppColors.navy,
        background: AppColors.white,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'textPrimary_on_background',
        foreground: AppColors.textPrimary,
        background: AppColors.background,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'textSecondary_on_white',
        foreground: AppColors.textSecondary,
        background: AppColors.white,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'white_on_navy_header',
        foreground: AppColors.white,
        background: AppColors.navy,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'white_on_ctaBackground',
        foreground: AppColors.white,
        background: CartTokens.ctaBackground,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'accentText_price_on_white',
        foreground: CartTokens.accentText,
        background: AppColors.white,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'dangerText_on_white',
        foreground: CartTokens.dangerText,
        background: AppColors.white,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'navy_on_surfaceMuted_stepper',
        foreground: AppColors.navy,
        background: CartTokens.surfaceMuted,
        requireAaNormal: true,
      ),
    ];

    for (final pair in pairs) {
      test(pair.id, () {
        final r = WcagContrast.ratio(pair.foreground, pair.background);
        if (pair.requireAaNormal) {
          expect(
            WcagContrast.passesAaNormal(pair.foreground, pair.background),
            isTrue,
            reason: '${pair.id} ratio=$r expected AA normal ≥ 4.5',
          );
        } else {
          expect(
            WcagContrast.passesAaLarge(pair.foreground, pair.background),
            isTrue,
            reason: '${pair.id} ratio=$r expected AA large ≥ 3.0',
          );
        }
      });
    }
  });

  group('Semantics — cart widgets', () {
    testWidgets('item card exposes name price stock quantity', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapCartGolden(
            CartItemCard(
              item: sampleCartItem(),
              onQuantityChanged: (_) {},
              onRemove: () {},
              onSwiped: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(RegExp('برجر كلاسيك')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('السعر')), findsWidgets);
        expect(
          find.bySemanticsLabel(RegExp('المتوفر|متاح|غير متاح')),
          findsWidgets,
        );
        expect(find.bySemanticsLabel(RegExp('الكمية')), findsWidgets);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('continue bar exposes total and CTA', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapCartGolden(
            CartContinueBar(
              totalLabel: 'المجموع',
              total: 155,
              ctaLabel: 'متابعة الطلب',
              onContinue: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(RegExp('متابعة الطلب')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('الإجمالي')), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('suggestion card is announced', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapCartGolden(
            CartSuggestedProductsSection(
              title: 'مقترحات لك',
              products: [sampleSuggestion()],
              loading: false,
              onAdd: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(RegExp('مقترح بطاطس')), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
