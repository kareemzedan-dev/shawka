import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/core/theme/wcag_contrast.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';
import 'package:matlobgo/screens/home/product/widgets/product_add_to_cart_bar.dart';
import 'package:matlobgo/screens/home/product/widgets/product_hero_actions.dart';
import 'package:matlobgo/screens/home/product/widgets/product_quantity_card.dart';

import 'golden/product_golden_helpers.dart';

void main() {
  setUpAll(prepareProductGoldens);

  group('WCAG contrast — product palette', () {
    final pairs = <CartContrastPair>[
      const CartContrastPair(
        id: 'textPrimary_on_sheet',
        foreground: ProductTokens.textPrimary,
        background: ProductTokens.sheet,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'textSecondary_on_sheet',
        foreground: ProductTokens.textSecondary,
        background: ProductTokens.sheet,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'price_accentText_on_sheet',
        foreground: ProductTokens.accentText,
        background: ProductTokens.sheet,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'white_on_ctaBackground',
        foreground: AppColors.white,
        background: ProductTokens.ctaBackground,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'white_on_ctaSuccess',
        foreground: AppColors.white,
        background: ProductTokens.discountBadgeText,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'discountBadge_text_on_bg',
        foreground: ProductTokens.discountBadgeText,
        background: ProductTokens.discountBadgeBackground,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'bestSellerBadge_text_on_bg',
        foreground: ProductTokens.bestSellerBadgeText,
        background: ProductTokens.bestSellerBadgeBackground,
        requireAaNormal: true,
      ),
      const CartContrastPair(
        id: 'heroChipText_on_heroChip',
        foreground: ProductTokens.heroChipText,
        background: ProductTokens.heroChipBackground,
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

  group('Semantics — product widgets', () {
    testWidgets('add-to-cart bar exposes CTA label and total', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapProductGolden(
            const SizedBox(
              width: 390,
              child: ProductAddToCartBar(
                state: ProductCtaState.normal,
                total: 300,
                unavailableReason: null,
                onAdd: _noop,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(RegExp('إضافة إلى السلة')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('جنيه')), findsWidgets);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('quantity stepper announces quantity and actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapProductGolden(
            ProductQuantityCard(
              quantity: 2,
              canIncrement: true,
              canDecrement: true,
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(RegExp('الكمية 2')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('زيادة الكمية')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('إنقاص الكمية')), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('hero actions expose back / share / favorite', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapProductGolden(
            ProductHeroActions(
              isFavorite: false,
              onBack: () {},
              onShare: () {},
              onToggleFavorite: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(RegExp('رجوع')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('مشاركة المنتج')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('إضافة للمفضلة')), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}

void _noop() {}
