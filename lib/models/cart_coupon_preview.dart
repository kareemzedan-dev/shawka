/// نتيجة معاينة الكوبون من [validateCartCoupon] — ليست نهائية مالياً.
class CartCouponPreview {
  const CartCouponPreview({
    required this.valid,
    required this.code,
    required this.discountAmount,
    required this.type,
    required this.freeDelivery,
    this.expiresAt,
    this.rejectionCode = '',
    this.message = '',
  });

  final bool valid;
  final String code;
  final double discountAmount;
  final String type;
  final bool freeDelivery;
  final DateTime? expiresAt;
  final String rejectionCode;
  final String message;

  factory CartCouponPreview.fromCallable(Map<String, dynamic> data) {
    final expiresMs = (data['expiresAt'] as num?)?.toInt() ?? 0;
    return CartCouponPreview(
      valid: data['valid'] as bool? ?? false,
      code: (data['code'] as String? ?? '').trim().toUpperCase(),
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      type: data['type'] as String? ?? '',
      freeDelivery: data['freeDelivery'] as bool? ?? false,
      expiresAt: expiresMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(expiresMs)
          : null,
      rejectionCode: (data['rejectionCode'] as String? ?? '').trim(),
      message: (data['message'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
    'valid': valid,
    'code': code,
    'discountAmount': discountAmount,
    'type': type,
    'freeDelivery': freeDelivery,
    if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
    if (rejectionCode.isNotEmpty) 'rejectionCode': rejectionCode,
    if (message.isNotEmpty) 'message': message,
  };
}
