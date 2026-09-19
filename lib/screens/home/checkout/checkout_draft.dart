import 'package:matlobgo/models/delivery_address.dart';

/// بيانات تُمرَّر من السلة إلى صفحة الدفع (UI state).
class CheckoutDraft {
  const CheckoutDraft({
    this.deliveryAddress,
    this.areaLine = '',
    this.streetLine = '',
    this.initialCouponCode = '',
    this.orderNote = '',
  });

  final DeliveryAddress? deliveryAddress;
  final String areaLine;
  final String streetLine;
  final String initialCouponCode;
  final String orderNote;

  bool get hasAddress =>
      deliveryAddress?.hasCoordinates == true || streetLine.trim().isNotEmpty;

  bool get hasValidGeoAddress => deliveryAddress?.hasCoordinates == true;

  String get fullAddress {
    if (deliveryAddress != null && deliveryAddress!.displayLine.isNotEmpty) {
      return deliveryAddress!.legacyAddressText;
    }
    return hasAddress ? '$areaLine\n$streetLine'.trim() : '';
  }
}
