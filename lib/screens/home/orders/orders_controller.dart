import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/repositories/orders_repository.dart';
import 'package:matlobgo/screens/home/checkout/order_details_screen.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/order_service.dart';

/// أقسام شاشة الطلبات.
enum OrdersTabKind { active, completed, cancelled }

/// حالة شاشة الطلبات — الـ UI يعتمد عليها فقط (لا Firestore/Services مباشرة).
///
/// يستمع لـ [OrderService] (بث لحظي عبر `watchByCustomer` مُصفّى بالمستخدم)
/// ويوجّه كل الإجراءات عبر [OrdersRepository].
///
/// مرجع: [ProductDetailsController].
class OrdersController extends ChangeNotifier {
  OrdersController({
    OrderService? orderService,
    OrdersRepository? repository,
  }) : _repo = repository ?? OrdersRepository(orderService: orderService) {
    _ordersListenable = _repo.ordersListenable;
    _ordersListenable.addListener(_onOrdersChanged);
    _loadingTimer = Timer(_initialLoadingWindow, _stopLoading);
    // إن كانت هناك بيانات جاهزة بالفعل، أنهِ التحميل فوراً.
    if (_repo.orders.isNotEmpty) _stopLoading();
    _trackOpenOnce();
  }

  final OrdersRepository _repo;
  late final Listenable _ordersListenable;
  Timer? _loadingTimer;

  static const _initialLoadingWindow = Duration(milliseconds: 700);

  int _selectedTab = 0;
  final Set<String> _expandedOrderIds = {};
  bool _loading = true;
  bool _offline = false;
  bool _openTracked = false;
  String? _notice;

  // ── Getters عامة للـ UI ──
  List<Order> get allOrders => _repo.orders;

  List<Order> get activeOrders =>
      allOrders.where((o) => o.status.isActive).toList(growable: false);

  List<Order> get completedOrders => allOrders
      .where((o) => o.status == OrderStatus.delivered)
      .toList(growable: false);

  List<Order> get cancelledOrders => allOrders
      .where((o) => o.status == OrderStatus.cancelled)
      .toList(growable: false);

  int get activeCount => activeOrders.length;
  int get completedCount => completedOrders.length;
  int get cancelledCount => cancelledOrders.length;

  bool get hasAnyOrders => allOrders.isNotEmpty;
  bool get loading => _loading && !hasAnyOrders;
  bool get offline => _offline;
  String? get notice => _notice;

  int get selectedTab => _selectedTab;
  OrdersTabKind get selectedKind => OrdersTabKind.values[_selectedTab];

  List<Order> ordersFor(OrdersTabKind kind) => switch (kind) {
        OrdersTabKind.active => activeOrders,
        OrdersTabKind.completed => completedOrders,
        OrdersTabKind.cancelled => cancelledOrders,
      };

  bool isExpanded(String orderId) => _expandedOrderIds.contains(orderId);

  // ── إجراءات المستخدم ──
  void selectTab(int index) {
    if (index == _selectedTab || index < 0 || index > 2) return;
    _selectedTab = index;
    notifyListeners();
  }

  /// تبديل توسيع تفاصيل الطلب (بناء كسول: الـ UI يبني التفاصيل عند التوسيع فقط).
  void toggleExpand(String orderId) {
    final nowExpanded = !_expandedOrderIds.contains(orderId);
    if (nowExpanded) {
      _expandedOrderIds.add(orderId);
      _track(
        AnalyticsEventType.orderExpand,
        label: 'توسيع تفاصيل الطلب',
        orderId: orderId,
      );
    } else {
      _expandedOrderIds.remove(orderId);
    }
    notifyListeners();
  }

  /// سحب للتحديث — البث لحظي، لذا مجرد إعادة إشعار (مع نقطة امتداد بالمستودع).
  Future<void> refresh() async {
    await _repo.refresh();
    notifyListeners();
  }

  /// فتح تفاصيل الطلب (بدون شاشة تتبع المندوب).
  void trackOrder(BuildContext context, Order order) {
    _track(
      AnalyticsEventType.orderTrack,
      label: 'تفاصيل ${order.storeName}',
      orderId: order.id,
      storeId: order.storeId,
      storeName: order.storeName,
    );
    openOrderDetailsScreen(context, order: order);
  }

  /// إعادة الطلب — يُوجَّه عبر المستودع ([ReorderService]) + تتبّع + إشعار.
  Future<void> reorder(Order order) async {
    final added = await _repo.reorder(order);
    _track(
      AnalyticsEventType.orderReorder,
      label: 'إعادة طلب ${order.storeName}',
      orderId: order.id,
      storeId: order.storeId,
      storeName: order.storeName,
      metadata: {'items': added},
    );
    _setNotice(
      added > 0
          ? 'تمت إضافة أصناف الطلب إلى السلة'
          : 'تعذّرت إعادة الطلب — قد لا تكون الأصناف متاحة',
    );
    notifyListeners();
  }

  /// إلغاء الطلب عبر المستودع ([OrderCancelService]) + تتبّع + إشعار.
  Future<void> cancel(Order order) async {
    if (!order.canCustomerCancel) return;
    _track(
      AnalyticsEventType.orderCancel,
      label: 'إلغاء ${order.storeName}',
      orderId: order.id,
      storeId: order.storeId,
      storeName: order.storeName,
    );
    try {
      await _repo.cancel(orderId: order.id);
      _setNotice('تم إلغاء الطلب');
    } catch (error) {
      _setNotice(error.toString());
    }
    notifyListeners();
  }

  Future<String?> resolveProductImage({
    required String storeId,
    required String productId,
  }) =>
      _repo.resolveProductImage(storeId: storeId, productId: productId);

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }

  // ── داخلي ──
  void _onOrdersChanged() {
    _offline = false;
    if (hasAnyOrders) _stopLoading();
    notifyListeners();
  }

  void _stopLoading() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    if (_loading) {
      _loading = false;
      notifyListeners();
    }
  }

  void _trackOpenOnce() {
    if (_openTracked) return;
    _openTracked = true;
    _track(AnalyticsEventType.ordersOpen, label: 'فتح الطلبات');
  }

  void _setNotice(String message) => _notice = message;

  /// التتبّع طرفي (fire-and-forget) — لا يجب أن يُفشل أي تدفّق للمستخدم.
  void _track(
    AnalyticsEventType type, {
    required String label,
    String? orderId,
    String storeId = '',
    String storeName = '',
    Map<String, dynamic>? metadata,
  }) {
    try {
      unawaited(
        AnalyticsService.instance.track(
          type: type,
          screen: 'orders',
          label: label,
          storeId: storeId,
          storeName: storeName,
          metadata: {
            'orderId': ?orderId,
            ...?metadata,
          },
        ),
      );
    } catch (_) {
      // تجاهل — التتبّع لا يؤثّر على المنطق.
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _ordersListenable.removeListener(_onOrdersChanged);
    super.dispose();
  }
}
