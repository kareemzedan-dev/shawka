import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/cart_repository.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/checkout_service.dart';

/// طبقة مستودع Checkout — UI لا يستدعي CartService مباشرة.
///
/// الأسعار النهائية تبقى من السيرفر عبر [CheckoutService] → CF.
class CheckoutRepository {
  CheckoutRepository({
    CartRepository? cartRepository,
    CartService? cartService,
  }) : _cartRepo = cartRepository ??
            (cartService != null
                ? CartRepository(service: cartService)
                : CartRepository.instance);

  final CartRepository _cartRepo;

  CartRepository get cart => _cartRepo;
  CartService get cartService => _cartRepo.service;

  List<CartItem> get items => _cartRepo.items;
  bool get isEmpty => _cartRepo.isEmpty;
  int get itemCount => _cartRepo.itemCount;
  String get orderNote => _cartRepo.orderNote;

  void setOrderNote(String value) => _cartRepo.setOrderNote(value);

  void updateQuantity(String itemId, int quantity) =>
      _cartRepo.updateQuantity(itemId, quantity);

  String? validateDeliveryAddress(DeliveryAddress? address) =>
      _cartRepo.validateDeliveryAddress(address);

  CheckoutService createSession({
    required AppUser user,
    required Governorate governorate,
    DeliveryAddress? address,
    String couponCode = '',
  }) {
    return CheckoutService(
      cart: cartService,
      user: user,
      governorate: governorate,
      address: address,
      couponCode: couponCode,
    );
  }

  Future<CheckoutQuote> previewCheckout({
    required String governorate,
    required String customerId,
    required String customerName,
    String? phone,
    required DeliveryAddress deliveryAddress,
    String? couponCode,
    required String paymentMethod,
  }) {
    return cartService.previewCheckout(
      governorate: governorate,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      deliveryAddress: deliveryAddress,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
    );
  }

  Future<List<Order>> placeViaSession(CheckoutService session) =>
      session.placeOrder();
}
