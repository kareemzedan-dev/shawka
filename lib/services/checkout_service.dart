import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/delivery_address_session.dart';

class CheckoutService extends ChangeNotifier {
  CheckoutService({
    required CartService cart,
    required AppUser user,
    required Governorate governorate,
    DeliveryAddress? address,
    String couponCode = '',
  }) : _cart = cart,
       _user = user,
       _governorate = governorate,
       _address = address,
       _couponCode = couponCode.trim().toUpperCase(),
       checkoutRequestId = _newRequestId() {
    _cart.addListener(_onDependencyChanged);
    AppConfigService.instance.addListener(_onDependencyChanged);
    DeliveryAddressSession.instance.addListener(_onAddressSessionChanged);
    _selectInitialPaymentMethod();
    _bindRealtimeDocuments();
  }

  final CartService _cart;
  final AppUser _user;
  final Governorate _governorate;
  final String checkoutRequestId;
  DeliveryAddress? _address;
  String _couponCode;
  String _paymentMethodId = '';
  CheckoutQuote? _quote;
  Object? _error;
  String? _notice;
  bool _loading = false;
  bool _placing = false;
  bool _isStale = false;
  Timer? _debounce;
  Timer? _couponExpiryTimer;
  int _generation = 0;
  String _realtimeSignature = '';
  final List<StreamSubscription<dynamic>> _realtimeSubscriptions = [];

  CheckoutQuote? get quote => _quote;
  Object? get error => _error;
  String? get notice => _notice;
  bool get isLoading => _loading;
  bool get isPlacing => _placing;
  bool get isStale => _isStale;
  bool get canSubmit =>
      _quote != null && !_isStale && _error == null && !_placing;

  DeliveryAddress? get address => _address;
  String get couponCode => _couponCode;
  String get paymentMethodId => _paymentMethodId;

  List<CheckoutPaymentMethod> get paymentMethods {
    final methods =
        AppConfigService.instance.settings.checkoutPaymentMethods
            .where((method) => method.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final base = methods.isNotEmpty
        ? methods
        : AppSettings.fallbackPaymentMethods;
    final available = _quote?.availablePaymentMethods;
    if (available == null || available.isEmpty) return base;
    final filtered =
        base.where((method) => available.contains(method.id)).toList();
    return filtered.isNotEmpty ? filtered : base;
  }

  CheckoutPaymentMethod? get selectedPaymentMethod {
    for (final method in paymentMethods) {
      if (method.id == _paymentMethodId) return method;
    }
    return null;
  }

  void _selectInitialPaymentMethod() {
    final methods = paymentMethods;
    if (methods.isEmpty) {
      _paymentMethodId = '';
      return;
    }
    final last = _user.lastPaymentMethod;
    _paymentMethodId = methods.any((method) => method.id == last)
        ? last
        : methods.first.id;
  }

  void setAddress(DeliveryAddress address) {
    if (_address == address) return;
    _address = address;
    refresh();
  }

  void clearAddress({String? notice}) {
    if (_address == null && _quote == null) return;
    _address = null;
    _quote = null;
    _error = null;
    _isStale = false;
    _notice = notice ?? 'اختر عنوان توصيل للمتابعة';
    notifyListeners();
  }

  void setPaymentMethod(String id) {
    if (_paymentMethodId == id) return;
    _paymentMethodId = id;
    refresh();
  }

  void applyCoupon(String code) {
    final normalized = code.trim().toUpperCase();
    if (_couponCode == normalized) return;
    _couponCode = normalized;
    _bindRealtimeDocuments();
    refresh();
  }

  void removeCoupon() {
    if (_couponCode.isEmpty) return;
    _couponCode = '';
    _couponExpiryTimer?.cancel();
    _bindRealtimeDocuments();
    refresh();
  }

  void _onDependencyChanged() {
    final validIds = paymentMethods.map((method) => method.id).toSet();
    if (!validIds.contains(_paymentMethodId)) {
      _selectInitialPaymentMethod();
    }
    _bindRealtimeDocuments();
    refresh();
  }

  void _onAddressSessionChanged() {
    final next = DeliveryAddressSession.instance.address;
    if (next == null) {
      clearAddress(notice: 'تم حذف عنوان التوصيل — اختر عنواناً جديداً');
      return;
    }
    if (!next.hasCoordinates || next == _address) return;
    _address = next;
    _notice = 'تم تحديث عنوان التوصيل — جارٍ إعادة حساب الرسوم';
    refresh();
  }

  void _bindRealtimeDocuments() {
    final items = _cart.items;
    final signatureParts =
        items
            .map((item) => '${item.storeId}/${item.productId}')
            .toSet()
            .toList()
          ..sort();
    final signature = '${signatureParts.join('|')}#$_couponCode';
    if (signature == _realtimeSignature) return;
    _realtimeSignature = signature;
    for (final subscription in _realtimeSubscriptions) {
      unawaited(subscription.cancel());
    }
    _realtimeSubscriptions.clear();

    final firestore = FirebaseFirestore.instance;
    final storeIds = items.map((item) => item.storeId).toSet().toList();
    for (final chunk in _chunks(storeIds, 30)) {
      _realtimeSubscriptions.add(
        firestore
            .collection('stores')
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .skip(1)
            .listen(
              (_) => refresh(),
              onError: (_) {
                _isStale = _quote != null;
                _notice =
                    'تعذّر تحديث بيانات المتاجر — تحقق من الاتصال ثم أعد المحاولة';
                notifyListeners();
              },
            ),
      );
    }

    final productsByStore = <String, Set<String>>{};
    for (final item in items) {
      productsByStore
          .putIfAbsent(item.storeId, () => <String>{})
          .add(item.productId);
    }
    for (final entry in productsByStore.entries) {
      for (final chunk in _chunks(entry.value.toList(), 30)) {
        _realtimeSubscriptions.add(
          firestore
              .collection('stores')
              .doc(entry.key)
              .collection('products')
              .where(FieldPath.documentId, whereIn: chunk)
              .snapshots()
              .skip(1)
              .listen(
                (_) => refresh(),
                onError: (_) {
                  _isStale = _quote != null;
                  _notice =
                      'تعذّر تحديث المنتجات — تحقق من الاتصال ثم أعد المحاولة';
                  notifyListeners();
                },
              ),
        );
      }
    }

    if (_couponCode.isNotEmpty) {
      _realtimeSubscriptions.add(
        firestore
            .collection('promotions')
            .where('code', isEqualTo: _couponCode)
            .limit(1)
            .snapshots()
            .skip(1)
            .listen(
              (_) => refresh(),
              onError: (_) {
                _isStale = _quote != null;
                _notice =
                    'تعذّر التحقق من الكوبون — تحقق من الاتصال ثم أعد المحاولة';
                notifyListeners();
              },
            ),
      );
    }
  }

  Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
    for (var offset = 0; offset < values.length; offset += size) {
      yield values.sublist(offset, min(offset + size, values.length));
    }
  }

  void refresh({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      unawaited(_loadQuote());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _loadQuote);
  }

  Future<void> _loadQuote() async {
    final address = _address;
    if (address == null ||
        !address.hasCoordinates ||
        _cart.isEmpty ||
        _paymentMethodId.isEmpty) {
      _quote = null;
      _error = null;
      _notice = null;
      _isStale = false;
      _loading = false;
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final previous = _quote;
      final quote = await _cart.previewCheckout(
        governorate: _governorate.name,
        customerId: _user.uid,
        customerName: _user.name,
        phone: _user.phone.isEmpty ? null : _user.phone,
        deliveryAddress: address,
        couponCode: _couponCode.isEmpty ? null : _couponCode,
        paymentMethod: _paymentMethodId,
      );
      if (generation != _generation) return;
      _quote = quote;
      _error = null;
      _isStale = false;
      if (previous != null && _pricingChanged(previous, quote)) {
        _notice = 'تم تحديث الأسعار والإجمالي وفق أحدث بيانات المتجر';
      } else {
        _notice = null;
      }
      _scheduleCouponExpiry(quote.couponExpiresAt);
    } catch (error) {
      if (generation != _generation) return;
      if (kDebugMode) {
        debugPrint('Checkout preview failed: $error');
      }
      _error = error;
      _notice = null;
      if (_isTransient(error) && _quote != null) {
        _isStale = true;
      } else {
        _quote = null;
        _isStale = false;
      }
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  bool _pricingChanged(CheckoutQuote previous, CheckoutQuote next) {
    if (previous.grandTotal != next.grandTotal ||
        previous.subtotal != next.subtotal ||
        previous.deliveryFee != next.deliveryFee ||
        previous.discountAmount != next.discountAmount) {
      return true;
    }
    final previousLines = previous.resolvedOrders
        .expand((order) => order.lineItems)
        .map((line) => '${line.productId}:${line.unitPrice}:${line.quantity}')
        .join('|');
    final nextLines = next.resolvedOrders
        .expand((order) => order.lineItems)
        .map((line) => '${line.productId}:${line.unitPrice}:${line.quantity}')
        .join('|');
    return previousLines != nextLines;
  }

  bool _isTransient(Object error) {
    if (error is FirebaseFunctionsException) {
      return const {
        'unavailable',
        'deadline-exceeded',
        'internal',
        'unknown',
      }.contains(error.code);
    }
    return false;
  }

  void _scheduleCouponExpiry(DateTime? expiresAt) {
    _couponExpiryTimer?.cancel();
    if (expiresAt == null) return;
    final delay = expiresAt.difference(DateTime.now());
    if (delay <= Duration.zero) {
      _notice = 'انتهت صلاحية الكوبون — جارٍ تحديث الأسعار';
      refresh(immediate: true);
      return;
    }
    _couponExpiryTimer = Timer(delay + const Duration(seconds: 1), () {
      _notice = 'انتهت صلاحية الكوبون — جارٍ تحديث الأسعار';
      notifyListeners();
      refresh(immediate: true);
    });
  }

  Future<List<Order>> placeOrder() async {
    if (_placing) {
      throw StateError('CHECKOUT_ALREADY_IN_PROGRESS');
    }
    final address = _address;
    if (address == null || !address.hasCoordinates) {
      throw StateError('DELIVERY_ADDRESS_REQUIRED');
    }
    if (_quote == null || _isStale) {
      await _loadQuote();
    }
    if (_quote == null || _isStale) {
      final error = _error;
      if (error is FirebaseFunctionsException) throw error;
      throw StateError('CHECKOUT_QUOTE_REQUIRED');
    }

    _placing = true;
    notifyListeners();
    try {
      return await _cart.checkout(
        governorate: _governorate.name,
        customerId: _user.uid,
        customerName: _user.name,
        phone: _user.phone.isEmpty ? null : _user.phone,
        deliveryAddress: address,
        couponCode: _couponCode.isEmpty ? null : _couponCode,
        paymentMethod: _paymentMethodId,
        checkoutRequestId: checkoutRequestId,
      );
    } catch (_) {
      unawaited(_loadQuote());
      rethrow;
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  static String _newRequestId() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _couponExpiryTimer?.cancel();
    for (final subscription in _realtimeSubscriptions) {
      unawaited(subscription.cancel());
    }
    _cart.removeListener(_onDependencyChanged);
    AppConfigService.instance.removeListener(_onDependencyChanged);
    DeliveryAddressSession.instance.removeListener(_onAddressSessionChanged);
    super.dispose();
  }
}
