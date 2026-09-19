import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/services/delivery_pricing_service.dart';

/// عنوان التوصيل النشط في السلة + تسعير الطريق.
class DeliveryAddressSession extends ChangeNotifier {
  DeliveryAddressSession._();
  static final DeliveryAddressSession instance = DeliveryAddressSession._();

  DeliveryAddress? _address;
  DeliveryQuote? _quote;

  DeliveryAddress? get address => _address;
  DeliveryQuote? get quote => _quote;

  bool get hasValidAddress => _address?.hasCoordinates == true;

  void setAddress(DeliveryAddress? value, {DeliveryQuote? quote}) {
    _address = value;
    _quote = quote;
    notifyListeners();
  }

  void setQuote(DeliveryQuote quote) {
    _quote = quote;
    notifyListeners();
  }

  void clear() {
    _address = null;
    _quote = null;
    notifyListeners();
  }
}
