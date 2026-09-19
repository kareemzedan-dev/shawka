/// صنف داخل الطلب — للتقارير والتحليلات.
class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitPrice = 0,
    this.addonIds = const [],
    this.note = '',
    this.imageUrl = '',
    this.imageThumbUrl = '',
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final List<String> addonIds;
  final String note;
  /// صورة المنتج وقت الطلب (اختيارية — للمعاينة في بطاقة الطلب).
  final String imageUrl;
  final String imageThumbUrl;

  factory OrderLineItem.fromMap(Map<String, dynamic> data) {
    return OrderLineItem(
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 1,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      addonIds: List<String>.from(data['addonIds'] as List? ?? const []),
      note: data['note'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      imageThumbUrl: data['imageThumbUrl'] as String? ??
          data['imageUrl'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        if (addonIds.isNotEmpty) 'addonIds': addonIds,
        if (note.isNotEmpty) 'note': note,
        if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (imageThumbUrl.isNotEmpty) 'imageThumbUrl': imageThumbUrl,
      };
}
