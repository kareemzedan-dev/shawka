import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/checkout_repository.dart';
import 'package:matlobgo/screens/home/checkout/checkout_draft.dart';
import 'package:matlobgo/screens/home/checkout/checkout_error_message.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/checkout_service.dart';

/// حالة شاشة الدفع — UI يعتمد عليها فقط (مرجع CartController).
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required this.governorate,
    required AppUser user,
    required CheckoutDraft draft,
    CheckoutRepository? repository,
  }) : _user = user,
       _repo = repository ?? CheckoutRepository(),
       _deliveryAddress = draft.deliveryAddress {
    final coupon = draft.initialCouponCode.trim();
    if (draft.orderNote.isNotEmpty && _repo.orderNote.isEmpty) {
      _repo.setOrderNote(draft.orderNote);
    }
    _session = _repo.createSession(
      user: user,
      governorate: governorate,
      address: _deliveryAddress,
      couponCode: coupon,
    );
    _session.addListener(_onSessionChanged);
    _repo.cartService.addListener(_onCartChanged);
    _session.refresh(immediate: true);
  }

  final Governorate governorate;
  final AppUser _user;
  final CheckoutRepository _repo;
  late final CheckoutService _session;

  DeliveryAddress? _deliveryAddress;
  String? _uiError;
  bool _confirming = false;
  bool _couponExpanded = false;

  CheckoutRepository get repository => _repo;
  AppUser get user => _user;
  List<CartItem> get items => _repo.items;
  bool get isEmpty => _repo.isEmpty;
  String get orderNote => _repo.orderNote;

  DeliveryAddress? get deliveryAddress => _deliveryAddress;
  CheckoutQuote? get quote => _session.quote;
  Object? get sessionError => _session.error;
  String? get notice => _session.notice;
  bool get isLoading => _session.isLoading;
  bool get isPlacing => _session.isPlacing;
  bool get isStale => _session.isStale;
  bool get canSubmit => _session.canSubmit && !_confirming;
  String get couponCode => _session.couponCode;
  String get paymentMethodId => _session.paymentMethodId;
  List<CheckoutPaymentMethod> get paymentMethods => _session.paymentMethods;
  CheckoutPaymentMethod? get selectedPaymentMethod =>
      _session.selectedPaymentMethod;
  String get checkoutRequestId => _session.checkoutRequestId;

  String? get uiError => _uiError;
  bool get confirming => _confirming;
  bool get couponExpanded => _couponExpanded;

  String? get displayError {
    if (_uiError != null) return _uiError;
    final err = _session.error;
    if (err == null) return null;
    return checkoutErrorMessage(err);
  }

  void _onSessionChanged() {
    // مزامنة العنوان عند الحذف/التحديث من الجلسة العامة.
    if (_session.address != _deliveryAddress) {
      _deliveryAddress = _session.address;
    }
    notifyListeners();
  }

  void _onCartChanged() => notifyListeners();

  void clearUiError() {
    if (_uiError == null) return;
    _uiError = null;
    notifyListeners();
  }

  void setCouponExpanded(bool value) {
    if (_couponExpanded == value) return;
    _couponExpanded = value;
    notifyListeners();
  }

  void setOrderNote(String value) {
    _repo.setOrderNote(value);
    notifyListeners();
  }

  void setAddress(DeliveryAddress address) {
    _deliveryAddress = address;
    _uiError = null;
    _session.setAddress(address);
    notifyListeners();
  }

  void clearAddress() {
    _deliveryAddress = null;
    _uiError = null;
    _session.clearAddress();
    notifyListeners();
  }

  void setPaymentMethod(String id) => _session.setPaymentMethod(id);

  void applyCoupon(String code) => _session.applyCoupon(code);

  void removeCoupon() => _session.removeCoupon();

  void refreshQuote({bool immediate = false}) =>
      _session.refresh(immediate: immediate);

  void updateLineQuantity(String itemId, int quantity) {
    _repo.updateQuantity(itemId, quantity);
  }

  CartItem? cartItemFor(CheckoutResolvedLine line) {
    for (final item in items) {
      if (item.productId == line.productId &&
          item.note == line.note &&
          listEquals(item.addonIds, line.addonIds)) {
        return item;
      }
    }
    return null;
  }

  String? validateBeforePlace() {
    if (isEmpty) return 'السلة فارغة — أضف منتجات أولاً';
    final addressError = _repo.validateDeliveryAddress(_deliveryAddress);
    if (addressError != null) return addressError;
    if (isStale) {
      return 'تم تحديث البيانات — راجع الإجمالي ثم أكّد مرة أخرى';
    }
    return null;
  }

  Future<List<Order>?> placeOrder() async {
    // منع الضغط المتكرر / إنشاء طلب مزدوج من العميل.
    if (_confirming || _session.isPlacing) return null;

    _uiError = null;
    final gate = validateBeforePlace();
    if (gate != null) {
      _uiError = gate;
      notifyListeners();
      return null;
    }
    final address = _deliveryAddress;
    if (address == null) {
      _uiError = 'اختر عنوان التوصيل أولاً';
      notifyListeners();
      return null;
    }

    _confirming = true;
    notifyListeners();
    try {
      _session.setAddress(address);
      final orders = await _repo.placeViaSession(_session);
      if (orders.isEmpty) {
        _uiError = 'تعذّر إنشاء الطلب — حاول مرة أخرى';
        return null;
      }
      await AnalyticsService.instance.track(
        type: AnalyticsEventType.orderPlaced,
        screen: 'checkout',
        label: 'طلب مكتمل · ${orders.length} طلب',
        metadata: {
          'orderIds': orders.map((order) => order.id).toList(),
          'orderCount': orders.length,
          'requestId': checkoutRequestId,
          'total': orders.fold<double>(
            0,
            (total, order) => total + order.grandTotal,
          ),
        },
      );
      return orders;
    } catch (error) {
      _uiError = checkoutErrorMessage(error);
      return null;
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _repo.cartService.removeListener(_onCartChanged);
    _session.dispose();
    super.dispose();
  }
}
