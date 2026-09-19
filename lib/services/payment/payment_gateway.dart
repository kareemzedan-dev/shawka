/// Payment gateway abstraction — ready for Paymob / Stripe / MyFatoorah.
abstract class PaymentGateway {
  const PaymentGateway();

  String get id;
  String get displayNameAr;
  bool get isAvailable;

  Future<PaymentResult> charge(PaymentRequest request);
}

class PaymentRequest {
  const PaymentRequest({
    required this.orderIds,
    required this.amount,
    required this.currency,
    required this.customerId,
    this.metadata = const {},
  });

  final List<String> orderIds;
  final double amount;
  final String currency;
  final String customerId;
  final Map<String, String> metadata;
}

class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.method,
    this.transactionId,
    this.errorMessage,
  });

  final bool success;
  final String method;
  final String? transactionId;
  final String? errorMessage;
}

/// Default production path — cash on delivery.
class CashOnDeliveryGateway extends PaymentGateway {
  const CashOnDeliveryGateway();

  @override
  String get id => 'cash';

  @override
  String get displayNameAr => 'الدفع عند الاستلام';

  @override
  bool get isAvailable => true;

  @override
  Future<PaymentResult> charge(PaymentRequest request) async {
    return PaymentResult(
      success: true,
      method: id,
      transactionId: 'cod_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

class PaymobGateway extends PaymentGateway {
  const PaymobGateway({this.configured = false});
  final bool configured;

  @override
  String get id => 'paymob';

  @override
  String get displayNameAr => 'Paymob';

  @override
  bool get isAvailable => configured;

  @override
  Future<PaymentResult> charge(PaymentRequest request) async {
    return const PaymentResult(
      success: false,
      method: 'paymob',
      errorMessage: 'Paymob — فعّل المفاتيح في AppSettings',
    );
  }
}

class PaymentGatewayRegistry {
  PaymentGatewayRegistry._();
  static final instance = PaymentGatewayRegistry._();

  List<PaymentGateway> gateways({bool paymobConfigured = false}) => [
        const CashOnDeliveryGateway(),
        PaymobGateway(configured: paymobConfigured),
      ];

  PaymentGateway defaultGateway() => const CashOnDeliveryGateway();
}
