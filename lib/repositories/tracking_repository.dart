import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/services/order_cancel_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/services/order_tracking_routes.dart';
import 'package:matlobgo/services/reorder_service.dart';

/// مستودع تتبع الطلب — واجهة مستقرة للـ TrackingController.
class TrackingRepository {
  TrackingRepository({
    OrderService? orderService,
    UserRepository? userRepository,
    StoreRepository? storeRepository,
    OrderCancelService? cancelService,
    ReorderService? reorderService,
    OrderTrackingRoutesLoader? routesLoader,
  })  : _orderServiceOverride = orderService,
        _userOverride = userRepository,
        _storeOverride = storeRepository,
        _cancelOverride = cancelService,
        _reorderOverride = reorderService,
        _routesOverride = routesLoader;

  final OrderService? _orderServiceOverride;
  final UserRepository? _userOverride;
  final StoreRepository? _storeOverride;
  final OrderCancelService? _cancelOverride;
  final ReorderService? _reorderOverride;
  final OrderTrackingRoutesLoader? _routesOverride;

  UserRepository? _userCached;
  StoreRepository? _storeCached;
  OrderCancelService? _cancelCached;
  ReorderService? _reorderCached;
  OrderTrackingRoutesLoader? _routesCached;

  OrderService get _orders => _orderServiceOverride ?? OrderService.instance;
  UserRepository get _users =>
      _userOverride ?? (_userCached ??= UserRepository());
  StoreRepository get _stores =>
      _storeOverride ?? (_storeCached ??= StoreRepository());
  OrderCancelService get _cancel =>
      _cancelOverride ?? (_cancelCached ??= OrderCancelService());
  ReorderService get _reorder =>
      _reorderOverride ?? (_reorderCached ??= ReorderService());
  OrderTrackingRoutesLoader get _routes =>
      _routesOverride ?? (_routesCached ??= OrderTrackingRoutesLoader());

  Listenable get ordersListenable => _orders;

  Order? getById(String id) => _orders.getById(id);

  Stream<AppUser?> watchDriver(String? deliveryId) {
    if (deliveryId == null || deliveryId.isEmpty) {
      return Stream<AppUser?>.value(null);
    }
    return _users.watchUser(deliveryId);
  }

  Future<Store?> getStore(String storeId) {
    if (storeId.isEmpty) return Future.value(null);
    return _stores.getStore(storeId);
  }

  Future<OrderTrackingRouteBundle> loadRoutes({
    required Order order,
    required OrderTrackingSnapshot snapshot,
    Store? storeDoc,
    AppUser? driver,
  }) {
    return _routes.load(
      order: order,
      snapshot: snapshot,
      storeDoc: storeDoc,
      driver: driver,
    );
  }

  Future<void> cancel(String orderId) =>
      _cancel.cancelOrder(orderId: orderId);

  Future<int> reorder(Order order) => _reorder.refillFromOrder(order);
}
