import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/tracking_repository.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/order_service.dart';

enum TrackingUiPhase {
  loading,
  waitingDriver,
  preparing,
  onTheWay,
  delivered,
  cancelled,
  error,
  offline,
}

/// حالة شاشة التتبع — UI يعتمد عليها فقط (RI v7).
class TrackingController extends ChangeNotifier {
  TrackingController({
    required Order initialOrder,
    OrderService? orderService,
    TrackingRepository? repository,
  })  : _order = initialOrder,
        _repo = repository ??
            TrackingRepository(orderService: orderService) {
    _ordersListenable = _repo.ordersListenable;
    _ordersListenable.addListener(_onOrdersUpdated);
    unawaited(_bootstrap());
    _trackOpen();
  }

  final TrackingRepository _repo;
  late final Listenable _ordersListenable;

  Order _order;
  Store? _storeDoc;
  AppUser? _driverUser;
  StreamSubscription<AppUser?>? _driverSub;
  Timer? _routeDebounce;
  OrderTrackingSnapshot? _mapSnapshot;
  bool _followDriver = false;
  bool _loading = true;
  bool _offline = false;
  bool _ratingPrompted = false;
  String? _notice;
  String? _error;

  Order get order => _order;
  Store? get storeDoc => _storeDoc;
  AppUser? get driverUser => _driverUser;
  OrderTrackingSnapshot get snapshot =>
      _mapSnapshot ??
      OrderTrackingUiData.build(_order, storeDoc: _storeDoc, driver: _driverUser);
  bool get followDriver => _followDriver;
  bool get loading => _loading;
  bool get offline => _offline;
  bool get ratingPrompted => _ratingPrompted;
  String? get notice => _notice;
  String? get error => _error;

  TrackingDriverInfo? get driverInfo => snapshot.driverInfo;
  bool get canCallDriver =>
      (driverInfo?.phone.trim().length ?? 0) >= 10;
  bool get showLiveBadge =>
      _order.status == OrderStatus.onTheWay || snapshot.usesLiveDriverGps;

  TrackingUiPhase get phase {
    if (_offline) return TrackingUiPhase.offline;
    if (_error != null && _loading) return TrackingUiPhase.error;
    if (_loading && _mapSnapshot == null) return TrackingUiPhase.loading;
    return switch (_order.status) {
      OrderStatus.cancelled => TrackingUiPhase.cancelled,
      OrderStatus.delivered => TrackingUiPhase.delivered,
      OrderStatus.onTheWay => TrackingUiPhase.onTheWay,
      OrderStatus.pending ||
      OrderStatus.preparing ||
      OrderStatus.readyForPickup =>
        _order.hasAssignedDriver
            ? TrackingUiPhase.preparing
            : TrackingUiPhase.waitingDriver,
    };
  }

  Future<void> _bootstrap() async {
    try {
      _storeDoc = await _repo.getStore(_order.storeId);
      _offline = false;
      _error = null;
    } catch (_) {
      _offline = true;
      _error = 'تعذّر تحميل بيانات المتجر';
    }
    _bindDriverStream();
    _loading = false;
    notifyListeners();
    _scheduleRouteRefresh();
  }

  void _bindDriverStream() {
    _driverSub?.cancel();
    _driverSub = _repo.watchDriver(_order.deliveryId).listen(
      (user) {
        _driverUser = user;
        _scheduleRouteRefresh();
        notifyListeners();
      },
      onError: (_) {
        _offline = true;
        notifyListeners();
      },
    );
  }

  void _onOrdersUpdated() {
    final latest = _repo.getById(_order.id);
    if (latest == null) return;
    final driverChanged = latest.deliveryId != _order.deliveryId;
    _order = latest;
    if (driverChanged) _bindDriverStream();
    _scheduleRouteRefresh();
    notifyListeners();
  }

  void _scheduleRouteRefresh() {
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_refreshRoutes());
    });
  }

  Future<void> _refreshRoutes() async {
    final base = OrderTrackingUiData.build(
      _order,
      storeDoc: _storeDoc,
      driver: _driverUser,
    );
    try {
      final bundle = await _repo.loadRoutes(
        order: _order,
        snapshot: base,
        storeDoc: _storeDoc,
        driver: _driverUser,
      );
      _mapSnapshot = base.copyWithRoutes(
        primary: bundle.primaryPoints,
        secondary: bundle.secondaryPoints,
        etaMinutes:
            bundle.etaMinutes > 0 ? bundle.etaMinutes : base.etaMinutes,
        distanceKm:
            bundle.distanceKm > 0 ? bundle.distanceKm : base.distanceKm,
      );
      _offline = false;
      notifyListeners();
    } catch (_) {
      _mapSnapshot = base;
      notifyListeners();
    }
  }

  void toggleFollowDriver() {
    _followDriver = !_followDriver;
    notifyListeners();
    if (_followDriver) _scheduleRouteRefresh();
  }

  void markRatingPrompted() => _ratingPrompted = true;

  void clearNotice() => _notice = null;

  Future<int> reorder() => _repo.reorder(_order);

  Future<void> cancel() async {
    await _repo.cancel(_order.id);
    _notice = 'تم إلغاء الطلب';
    notifyListeners();
  }

  void _trackOpen() {
    unawaited(
      AnalyticsService.instance.track(
        type: AnalyticsEventType.orderTrack,
        screen: 'order_tracking',
        label: 'تتبع ${_order.storeName}',
        storeId: _order.storeId,
        storeName: _order.storeName,
        metadata: {'orderId': _order.id, 'event': 'tracking_open'},
      ),
    );
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _driverSub?.cancel();
    _ordersListenable.removeListener(_onOrdersUpdated);
    super.dispose();
  }
}

/// عناوين/أوصاف مراحل التتبع الأربع (تصميم SSOT).
abstract final class TrackingTimelineData {
  static const titles = [
    'تم استلام الطلب',
    'جاري التحضير',
    'في الطريق إليك',
    'تم التوصيل',
  ];

  static int activeIndex(OrderStatus status) => switch (status) {
        OrderStatus.pending => 0,
        OrderStatus.preparing => 1,
        OrderStatus.readyForPickup => 2,
        OrderStatus.onTheWay => 2,
        OrderStatus.delivered => 3,
        OrderStatus.cancelled => -1,
      };

  static String statusTitle(Order order) => switch (order.status) {
        OrderStatus.pending => 'بانتظار قبول المتجر',
        OrderStatus.preparing => 'جاري التحضير',
        OrderStatus.readyForPickup =>
          order.hasAssignedDriver ? 'السائق في المتجر' : 'جاهز للاستلام',
        OrderStatus.onTheWay => 'في الطريق إليك',
        OrderStatus.delivered => 'تم التوصيل',
        OrderStatus.cancelled => 'تم إلغاء الطلب',
      };

  static String statusSubtitle(Order order) => switch (order.status) {
        OrderStatus.pending => 'طلبك قيد المراجعة الآن',
        OrderStatus.preparing => 'يتم تجهيز طلبك الآن',
        OrderStatus.readyForPickup =>
          order.hasAssignedDriver
              ? 'السائق يستلم الطلب حالياً'
              : 'بانتظار تعيين مندوب',
        OrderStatus.onTheWay => 'المندوب في الطريق إليك',
        OrderStatus.delivered => 'بالهناء والشفاء',
        OrderStatus.cancelled => 'لن يتم التوصيل',
      };

  static String stepSubtitle(Order order, int index, int active) {
    if (index > active) {
      if (index == 3) return 'الوصول المتوقع';
      return 'قريباً';
    }
    if (index < active) return 'مكتمل';
    return statusSubtitle(order);
  }

  static DateTime? stepTime(Order order, int index) {
    return switch (index) {
      0 => order.createdAt,
      1 => order.status.index >= OrderStatus.preparing.index
          ? order.updatedAt
          : null,
      2 => order.deliveryPickedUpAt ??
          (order.status == OrderStatus.onTheWay ||
                  order.status == OrderStatus.readyForPickup
              ? order.updatedAt
              : null),
      3 => order.deliveryDeliveredAt,
      _ => null,
    };
  }

  static String formatClock(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  static String etaArrivalLabel(int etaMinutes) {
    if (etaMinutes <= 0) return '—';
    final arrival = DateTime.now().add(Duration(minutes: etaMinutes));
    return 'الوصول المتوقع ${formatClock(arrival)}';
  }

  static String etaMinutesLabel(Order order, int snapshotEta) {
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return '—';
    }
    final minutes = snapshotEta > 0
        ? snapshotEta
        : (order.etaMinutes > 0 ? order.etaMinutes : 0);
    if (minutes <= 0) return '—';
    return '$minutes دقيقة';
  }
}
