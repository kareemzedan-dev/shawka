import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/debug/cart_preview.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_free_delivery_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_header.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_item_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_summary_and_bar.dart';

import 'cart_golden_helpers.dart';

void main() {
  setUpAll(prepareCartGoldens);

  testWidgets('golden cart header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCartGolden(
        CartHeader(
          title: 'سلة التسوق',
          subtitle: '2 أصناف في سلتك',
          onBack: () {},
        ),
        size: const Size(390, 160),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CartHeader),
      matchesGoldenFile('goldens/cart_header.png'),
    );
  });

  testWidgets('golden cart item card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCartGolden(
        Padding(
          padding: const EdgeInsets.all(16),
          child: CartItemCard(
            item: sampleCartItem(),
            onQuantityChanged: (_) {},
            onRemove: () {},
            onSwiped: () {},
          ),
        ),
        size: const Size(390, 280),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CartItemCard),
      matchesGoldenFile('goldens/cart_item_card.png'),
    );
  });

  testWidgets('golden free delivery card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCartGolden(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CartFreeDeliveryCard(
            title: 'توصيل مجاني يقترب!',
            body: 'أضف 40 ج.م للحصول على العرض',
            progress: 0.72,
            unlocked: false,
          ),
        ),
        size: const Size(390, 200),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CartFreeDeliveryCard),
      matchesGoldenFile('goldens/cart_free_delivery_card.png'),
    );
  });

  testWidgets('golden continue bar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCartGolden(
        SizedBox(
          width: 390,
          child: CartContinueBar(
            totalLabel: 'المجموع',
            total: 155,
            ctaLabel: 'متابعة الطلب',
            onContinue: () {},
          ),
        ),
        size: const Size(390, 120),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CartContinueBar),
      matchesGoldenFile('goldens/cart_continue_bar.png'),
    );
  });

  testWidgets('golden full cart screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCartGolden(const CartPreviewScreen()),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CartPreviewScreen),
      matchesGoldenFile('goldens/cart_full_screen.png'),
    );
  });
}
