import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/core/theme/wcag_contrast.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_track_button.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_segmented_tabs.dart';

import 'golden/orders_golden_helpers.dart';

void main() {
  setUpAll(prepareOrdersGoldens);

  group('WCAG contrast — orders palette', () {
    final pairs = <({String id, Color fg, Color bg, bool aaNormal})>[
      (
        id: 'textPrimary_on_card',
        fg: OrdersTokens.textPrimary,
        bg: OrdersTokens.cardBackground,
        aaNormal: true,
      ),
      (
        id: 'textSecondary_on_card',
        fg: OrdersTokens.textSecondary,
        bg: OrdersTokens.cardBackground,
        aaNormal: true,
      ),
      (
        id: 'accentText_on_card',
        fg: OrdersTokens.accentText,
        bg: OrdersTokens.cardBackground,
        aaNormal: true,
      ),
      (
        id: 'accentText_on_etaFill',
        fg: OrdersTokens.accentText,
        bg: OrdersTokens.etaCardFill,
        aaNormal: true,
      ),
      (
        id: 'white_on_ctaBackground',
        fg: AppColors.white,
        bg: OrdersTokens.ctaBackground,
        aaNormal: true,
      ),
      (
        id: 'textPrimary_on_segmentSelected',
        fg: OrdersTokens.textPrimary,
        bg: OrdersTokens.segmentSelected,
        aaNormal: true,
      ),
      (
        id: 'segmentUnselected_on_segmentTrack',
        fg: OrdersTokens.segmentUnselectedText,
        bg: OrdersTokens.segmentTrack,
        aaNormal: true,
      ),
    ];

    for (final pair in pairs) {
      test(pair.id, () {
        final r = WcagContrast.ratio(pair.fg, pair.bg);
        if (pair.aaNormal) {
          expect(
            WcagContrast.passesAaNormal(pair.fg, pair.bg),
            isTrue,
            reason: '${pair.id} ratio=$r expected AA normal ≥ 4.5',
          );
        } else {
          expect(
            WcagContrast.passesAaLarge(pair.fg, pair.bg),
            isTrue,
            reason: '${pair.id} ratio=$r expected AA large ≥ 3.0',
          );
        }
      });
    }
  });

  group('Semantics — orders widgets', () {
    testWidgets('track button exposes CTA label', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapOrdersGolden(
            OrderTrackButton(onTap: () {}),
          ),
        );
        expect(find.bySemanticsLabel('تفاصيل الطلب'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('segmented tabs expose tab labels with counts', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrapOrdersGolden(
            OrdersSegmentedTabs(
              selectedIndex: 0,
              activeCount: 2,
              completedCount: 1,
              cancelledCount: 0,
              onSelect: (_) {},
            ),
          ),
        );
        expect(find.textContaining('نشطة'), findsOneWidget);
        expect(find.textContaining('مكتملة'), findsOneWidget);
        expect(find.textContaining('ملغية'), findsOneWidget);
        // Touch target height ≥ 48.
        final size = tester.getSize(find.byType(OrdersSegmentedTabs));
        expect(size.height, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });
  });
}
