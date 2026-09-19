import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/order_line_item.dart';
import 'package:matlobgo/repositories/orders_repository.dart';
import 'package:matlobgo/screens/home/orders/orders_controller.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_eta_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_horizontal_timeline.dart';

/// مستودع بديل بلا Firebase — يوفّر لقطة طلبات ثابتة + يسجّل التوجيه.
class _FakeOrdersRepository extends OrdersRepository {
  _FakeOrdersRepository({List<Order> orders = const []}) : _orders = orders;

  List<Order> _orders;
  final ChangeNotifier _notifier = ChangeNotifier();

  final List<Order> reorderCalls = [];
  final List<String> cancelCalls = [];
  int reorderResult = 0;

  set orders(List<Order> value) {
    _orders = value;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    _notifier.notifyListeners();
  }

  @override
  Listenable get ordersListenable => _notifier;

  @override
  List<Order> get orders => _orders;

  @override
  Future<int> reorder(Order order) async {
    reorderCalls.add(order);
    return reorderResult;
  }

  @override
  Future<void> cancel({
    required String orderId,
    String reason = 'customer_cancelled',
  }) async {
    cancelCalls.add(orderId);
  }

  @override
  Future<String?> resolveProductImage({
    required String storeId,
    required String productId,
  }) async =>
      null;
}

Order _order({
  String id = 'o1',
  OrderStatus status = OrderStatus.pending,
  DateTime? createdAt,
  int etaMinutes = 0,
  double total = 100,
  List<OrderLineItem> lineItems = const [],
}) =>
    Order(
      id: id,
      storeName: 'مطعم الاختبار',
      category: 'supplier',
      itemsSummary: 'برجر × 2',
      itemCount: 2,
      total: total,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 1, 1, 12),
      etaMinutes: etaMinutes,
      lineItems: lineItems,
    );

OrdersController _controller(_FakeOrdersRepository repo) =>
    OrdersController(repository: repo);

void main() {
  group('OrdersTokens contract', () {
    test('design SSOT sizes match', () {
      expect(OrdersTokens.cardRadius, 22);
      expect(OrdersTokens.timelineDot, 28);
      expect(OrdersTokens.trackButtonHeight, 52);
    });

    test('aliases Cart tokens for WCAG-safe accent/CTA', () {
      expect(OrdersTokens.accentText, CartTokens.accentText);
      expect(OrdersTokens.ctaBackground, CartTokens.ctaBackground);
    });
  });

  group('OrderHorizontalTimeline index mapping', () {
    test('maps status → current step index per SSOT', () {
      expect(OrderHorizontalTimeline.stepIndexFor(OrderStatus.pending), 0);
      expect(OrderHorizontalTimeline.stepIndexFor(OrderStatus.preparing), 1);
      expect(
        OrderHorizontalTimeline.stepIndexFor(OrderStatus.readyForPickup),
        2,
      );
      expect(OrderHorizontalTimeline.stepIndexFor(OrderStatus.onTheWay), 2);
      expect(OrderHorizontalTimeline.stepIndexFor(OrderStatus.delivered), 3);
      expect(OrderHorizontalTimeline.stepIndexFor(OrderStatus.cancelled), -1);
    });

    test('delivered marks all steps done; others not', () {
      expect(OrderHorizontalTimeline.isAllDone(OrderStatus.delivered), isTrue);
      expect(OrderHorizontalTimeline.isAllDone(OrderStatus.onTheWay), isFalse);
      expect(OrderHorizontalTimeline.labels.length, 4);
    });
  });

  group('OrderEtaInfo delayed detection', () {
    test('shouldShow only for active orders with positive ETA', () {
      expect(OrderEtaInfo.shouldShow(_order(etaMinutes: 30)), isTrue);
      expect(OrderEtaInfo.shouldShow(_order(etaMinutes: 0)), isFalse);
      expect(
        OrderEtaInfo.shouldShow(
          _order(status: OrderStatus.delivered, etaMinutes: 30),
        ),
        isFalse,
      );
    });

    test('isDelayed true when now is past createdAt + eta', () {
      final created = DateTime(2026, 1, 1, 12);
      final order = _order(createdAt: created, etaMinutes: 30);
      // 20 دقيقة بعد الإنشاء — ضمن الوقت.
      expect(
        OrderEtaInfo.isDelayed(order, now: created.add(const Duration(minutes: 20))),
        isFalse,
      );
      // 45 دقيقة بعد الإنشاء — متأخّر.
      expect(
        OrderEtaInfo.isDelayed(order, now: created.add(const Duration(minutes: 45))),
        isTrue,
      );
    });

    test('never delayed when ETA is zero', () {
      expect(OrderEtaInfo.isDelayed(_order(etaMinutes: 0)), isFalse);
    });
  });

  group('OrdersController tab filtering + counts', () {
    test('splits orders into active / completed / cancelled', () {
      final repo = _FakeOrdersRepository(orders: [
        _order(id: 'a', status: OrderStatus.pending),
        _order(id: 'b', status: OrderStatus.onTheWay),
        _order(id: 'c', status: OrderStatus.delivered),
        _order(id: 'd', status: OrderStatus.cancelled),
        _order(id: 'e', status: OrderStatus.preparing),
      ]);
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      expect(controller.activeCount, 3);
      expect(controller.completedCount, 1);
      expect(controller.cancelledCount, 1);
      expect(
        controller.ordersFor(OrdersTabKind.active).map((o) => o.id),
        ['a', 'b', 'e'],
      );
      expect(
        controller.ordersFor(OrdersTabKind.completed).single.id,
        'c',
      );
      expect(
        controller.ordersFor(OrdersTabKind.cancelled).single.id,
        'd',
      );
    });

    test('selectTab updates selected kind', () {
      final repo = _FakeOrdersRepository();
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      expect(controller.selectedKind, OrdersTabKind.active);
      controller.selectTab(2);
      expect(controller.selectedKind, OrdersTabKind.cancelled);
    });
  });

  group('OrdersController expand toggle', () {
    test('toggles expansion state per order id', () {
      final repo = _FakeOrdersRepository(orders: [_order(id: 'o1')]);
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      expect(controller.isExpanded('o1'), isFalse);
      controller.toggleExpand('o1');
      expect(controller.isExpanded('o1'), isTrue);
      controller.toggleExpand('o1');
      expect(controller.isExpanded('o1'), isFalse);
    });
  });

  group('OrdersController repository routing', () {
    test('reorder routes through repository and notices result', () async {
      final repo = _FakeOrdersRepository()..reorderResult = 3;
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      final order = _order(id: 'o1');
      await controller.reorder(order);

      expect(repo.reorderCalls.single.id, 'o1');
      expect(controller.notice, isNotNull);
    });

    test('reorder with zero items surfaces a fallback notice', () async {
      final repo = _FakeOrdersRepository()..reorderResult = 0;
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      await controller.reorder(_order(id: 'o1'));
      expect(repo.reorderCalls, hasLength(1));
      expect(controller.notice, contains('تعذّر'));
    });

    test('cancel routes through repository for cancellable orders', () async {
      final repo = _FakeOrdersRepository();
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      await controller.cancel(_order(id: 'o1', status: OrderStatus.pending));
      expect(repo.cancelCalls.single, 'o1');

      // طلب مُسلّم لا يُلغى.
      await controller.cancel(_order(id: 'o2', status: OrderStatus.delivered));
      expect(repo.cancelCalls, hasLength(1));
    });
  });
}
