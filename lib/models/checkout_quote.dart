class CheckoutOrderQuote {
  const CheckoutOrderQuote({
    required this.storeId,
    required this.subtotal,
    required this.deliveryFee,
    required this.rawDeliveryFee,
    required this.discountAmount,
    required this.serviceFee,
    required this.paymentFee,
    required this.taxes,
    required this.grandTotal,
    required this.distanceKm,
    required this.etaMinutes,
  });

  final String storeId;
  final double subtotal;
  final double deliveryFee;
  final double rawDeliveryFee;
  final double discountAmount;
  final double serviceFee;
  final double paymentFee;
  final double taxes;
  final double grandTotal;
  final double distanceKm;
  final int etaMinutes;

  factory CheckoutOrderQuote.fromMap(Map<String, dynamic> map) {
    return CheckoutOrderQuote(
      storeId: map['storeId'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      rawDeliveryFee: (map['rawDeliveryFee'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceFee: (map['serviceFee'] as num?)?.toDouble() ?? 0,
      paymentFee: (map['paymentFee'] as num?)?.toDouble() ?? 0,
      taxes: (map['taxes'] as num?)?.toDouble() ?? 0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      etaMinutes: (map['etaMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class CheckoutResolvedLine {
  const CheckoutResolvedLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.addonIds,
    required this.note,
    required this.imageUrl,
    required this.imageThumbUrl,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final List<String> addonIds;
  final String note;
  final String imageUrl;
  final String imageThumbUrl;

  double get lineTotal => unitPrice * quantity;

  factory CheckoutResolvedLine.fromMap(Map<String, dynamic> map) {
    return CheckoutResolvedLine(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      addonIds: List<String>.from(map['addonIds'] as List? ?? const []),
      note: map['note'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      imageThumbUrl: map['imageThumbUrl'] as String? ?? '',
    );
  }
}

class CheckoutResolvedOrder {
  const CheckoutResolvedOrder({
    required this.storeId,
    required this.storeName,
    required this.lineItems,
  });

  final String storeId;
  final String storeName;
  final List<CheckoutResolvedLine> lineItems;

  factory CheckoutResolvedOrder.fromMap(Map<String, dynamic> map) {
    return CheckoutResolvedOrder(
      storeId: map['storeId'] as String? ?? '',
      storeName: map['storeName'] as String? ?? '',
      lineItems: (map['lineItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                CheckoutResolvedLine.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false),
    );
  }
}

/// Immutable server-authoritative Checkout snapshot.
class CheckoutQuote {
  const CheckoutQuote({
    required this.currency,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.serviceFee,
    required this.paymentFee,
    required this.taxes,
    required this.grandTotal,
    required this.couponCode,
    required this.couponExpiresAt,
    required this.distanceKm,
    required this.etaMinutes,
    required this.orders,
    required this.resolvedOrders,
    required this.availablePaymentMethods,
    required this.calculatedAt,
  });

  final String currency;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double serviceFee;
  final double paymentFee;
  final double taxes;
  final double grandTotal;
  final String couponCode;
  final DateTime? couponExpiresAt;
  final double distanceKm;
  final int etaMinutes;
  final List<CheckoutOrderQuote> orders;
  final List<CheckoutResolvedOrder> resolvedOrders;
  final List<String> availablePaymentMethods;
  final DateTime calculatedAt;

  factory CheckoutQuote.fromCallable(Map<String, dynamic> data) {
    final pricing = Map<String, dynamic>.from(
      data['pricing'] as Map? ?? const {},
    );
    return CheckoutQuote(
      currency: pricing['currency'] as String? ?? 'EGP',
      subtotal: (pricing['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (pricing['deliveryFee'] as num?)?.toDouble() ?? 0,
      discountAmount: (pricing['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceFee: (pricing['serviceFee'] as num?)?.toDouble() ?? 0,
      paymentFee: (pricing['paymentFee'] as num?)?.toDouble() ?? 0,
      taxes: (pricing['taxes'] as num?)?.toDouble() ?? 0,
      grandTotal: (pricing['grandTotal'] as num?)?.toDouble() ?? 0,
      couponCode: pricing['couponCode'] as String? ?? '',
      couponExpiresAt: switch ((pricing['couponExpiresAt'] as num?)?.toInt() ??
          0) {
        final ms when ms > 0 => DateTime.fromMillisecondsSinceEpoch(ms),
        _ => null,
      },
      distanceKm: (pricing['distanceKm'] as num?)?.toDouble() ?? 0,
      etaMinutes: (pricing['etaMinutes'] as num?)?.toInt() ?? 0,
      orders: (pricing['orders'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                CheckoutOrderQuote.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false),
      resolvedOrders: (data['orders'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                CheckoutResolvedOrder.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false),
      availablePaymentMethods: List<String>.from(
        data['availablePaymentMethods'] as List? ?? const [],
      ),
      calculatedAt: DateTime.fromMillisecondsSinceEpoch(
        (data['calculatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
