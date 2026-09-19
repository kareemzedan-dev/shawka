import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/repositories/order_repository.dart';

/// طلبات العميل — مزامنة حية مع Firestore (تظهر في لوحة التحكم فوراً).
class OrderService extends ChangeNotifier {
  OrderService._();

  static final OrderService instance = OrderService._();

  final _repo = OrderRepository();
  StreamSubscription<List<Order>>? _subscription;
  List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get activeOrders =>
      _orders.where((o) => o.status.isActive).toList();

  List<Order> get pastOrders =>
      _orders.where((o) => !o.status.isActive).toList();

  void bindCustomer(String? customerId) {
    _subscription?.cancel();
    _subscription = null;

    if (customerId == null || customerId.isEmpty) {
      _orders = [];
      notifyListeners();
      return;
    }

    _subscription = _repo.watchByCustomer(customerId).listen((orders) {
      _orders = orders;
      notifyListeners();
    }, onError: (_) {});
  }

  Order? getById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Order>> placeOrders(
    List<Order> drafts, {
    String? checkoutRequestId,
  }) async {
    return _repo.createOrders(drafts, checkoutRequestId: checkoutRequestId);
  }

  Future<CheckoutQuote> previewCheckout(List<Order> drafts) {
    return _repo.previewCheckout(drafts);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
