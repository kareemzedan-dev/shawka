import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_eta_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_segmented_tabs.dart';

import 'orders_golden_helpers.dart';

void main() {
  setUpAll(prepareOrdersGoldens);

  testWidgets('golden orders active card', (tester) async {
    final order = sampleOrdersGoldenOrder();
    await tester.binding.setSurfaceSize(const Size(390, 720));
    await tester.pumpWidget(
      wrapOrdersGolden(
        Padding(
          padding: const EdgeInsets.all(OrdersTokens.pagePadding),
          child: OrderCard(
            order: order,
            expanded: false,
            onToggleExpand: () {},
            onTrack: () {},
            onReorder: () {},
          ),
        ),
        size: const Size(390, 720),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OrderCard),
      matchesGoldenFile('goldens/orders_active_card.png'),
    );
  });

  testWidgets('golden orders completed card', (tester) async {
    final order = sampleOrdersGoldenOrder(status: OrderStatus.delivered);
    await tester.binding.setSurfaceSize(const Size(390, 520));
    await tester.pumpWidget(
      wrapOrdersGolden(
        Padding(
          padding: const EdgeInsets.all(OrdersTokens.pagePadding),
          child: OrderCard(
            order: order,
            expanded: false,
            onToggleExpand: () {},
            onTrack: () {},
            onReorder: () {},
          ),
        ),
        size: const Size(390, 520),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OrderCard),
      matchesGoldenFile('goldens/orders_completed_card.png'),
    );
  });

  testWidgets('golden orders eta card', (tester) async {
    final order = sampleOrdersGoldenOrder();
    await tester.binding.setSurfaceSize(const Size(390, 200));
    await tester.pumpWidget(
      wrapOrdersGolden(
        Padding(
          padding: const EdgeInsets.all(OrdersTokens.pagePadding),
          child: OrderEtaCard(order: order),
        ),
        size: const Size(390, 200),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OrderEtaCard),
      matchesGoldenFile('goldens/orders_eta_card.png'),
    );
  });

  testWidgets('golden orders segmented tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 120));
    await tester.pumpWidget(
      wrapOrdersGolden(
        Padding(
          padding: const EdgeInsets.all(OrdersTokens.pagePadding),
          child: OrdersSegmentedTabs(
            selectedIndex: 0,
            activeCount: 1,
            completedCount: 1,
            cancelledCount: 0,
            onSelect: (_) {},
          ),
        ),
        size: const Size(390, 120),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OrdersSegmentedTabs),
      matchesGoldenFile('goldens/orders_segmented_tabs.png'),
    );
  });

  testWidgets('golden orders cancelled card', (tester) async {
    final order = sampleOrdersGoldenOrder(status: OrderStatus.cancelled);
    await tester.binding.setSurfaceSize(const Size(390, 420));
    await tester.pumpWidget(
      wrapOrdersGolden(
        Padding(
          padding: const EdgeInsets.all(OrdersTokens.pagePadding),
          child: OrderCard(
            order: order,
            expanded: false,
            onToggleExpand: () {},
            onTrack: () {},
            onReorder: () {},
          ),
        ),
        size: const Size(390, 420),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OrderCard),
      matchesGoldenFile('goldens/orders_cancelled_card.png'),
    );
  });
}
