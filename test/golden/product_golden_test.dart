import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/debug/product_preview.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';
import 'package:matlobgo/screens/home/product/widgets/product_add_to_cart_bar.dart';
import 'package:matlobgo/screens/home/product/widgets/product_price_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_state_views.dart';

import 'product_golden_helpers.dart';

void main() {
  setUpAll(prepareProductGoldens);

  testWidgets('golden product full screen (loaded)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrapProductGolden(const ProductPreviewScreen()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProductPreviewScreen),
      matchesGoldenFile('goldens/product_full_screen.png'),
    );
  });

  testWidgets('golden product price section', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 140));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapProductGolden(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ProductPriceSection(product: productPreviewProduct()),
        ),
        size: const Size(390, 140),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProductPriceSection),
      matchesGoldenFile('goldens/product_price_section.png'),
    );
  });

  testWidgets('golden product suggestions loading skeleton', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapProductGolden(
        const ProductSuggestionsLoadingPreview(),
        size: const Size(390, 320),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProductSuggestionsLoadingPreview),
      matchesGoldenFile('goldens/product_suggestions_skeleton.png'),
    );
  });

  testWidgets('golden product add to cart bar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        size: const Size(390, 120),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProductAddToCartBar),
      matchesGoldenFile('goldens/product_add_to_cart_bar.png'),
    );
  });

  testWidgets('golden product unavailable state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapProductGolden(
        ProductMessageView.unavailable(onBack: () {}),
        size: const Size(390, 480),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProductMessageView),
      matchesGoldenFile('goldens/product_unavailable.png'),
    );
  });
}

void _noop() {}
