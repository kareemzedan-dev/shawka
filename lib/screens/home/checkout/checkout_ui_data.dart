import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/delivery_address_session.dart';

/// تقديرات توصيل من Directions (مسافة الطريق).
class CheckoutDeliveryEstimate {
  const CheckoutDeliveryEstimate({
    required this.etaMinutes,
    required this.distanceKm,
  });

  final int etaMinutes;
  final double distanceKm;
}

abstract final class CheckoutUiData {
  static CheckoutDeliveryEstimate deliveryEstimate({
    required CartService cart,
    required Governorate governorate,
    DeliveryAddress? address,
  }) {
    final quote = DeliveryAddressSession.instance.quote;
    if (quote != null && quote.isInZone) {
      return CheckoutDeliveryEstimate(
        etaMinutes: quote.etaMinutes > 0 ? quote.etaMinutes : 25,
        distanceKm: quote.distanceKm,
      );
    }

    return const CheckoutDeliveryEstimate(
      etaMinutes: 0,
      distanceKm: 0,
    );
  }

  static String formatOrderId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(id.length - 8).toUpperCase();
  }
}
