/// إعدادات واجهة السلة القابلة للتحكم من لوحة التحكم.
class CartUiSettings {
  const CartUiSettings({
    this.suggestionsEnabled = true,
    this.freeDeliveryProgressEnabled = true,
    this.sectionOrder = defaultSectionOrder,
  });

  final bool suggestionsEnabled;
  final bool freeDeliveryProgressEnabled;

  /// ترتيب الأقسام الاختيارية: freeDelivery | items | note | coupon | suggestions | summary
  final List<String> sectionOrder;

  static const defaultSectionOrder = [
    'freeDelivery',
    'items',
    'note',
    'coupon',
    'suggestions',
    'summary',
  ];

  factory CartUiSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CartUiSettings();
    final order = (map['sectionOrder'] as List?)
        ?.map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
    return CartUiSettings(
      suggestionsEnabled: map['suggestionsEnabled'] as bool? ?? true,
      freeDeliveryProgressEnabled:
          map['freeDeliveryProgressEnabled'] as bool? ?? true,
      sectionOrder: order == null || order.isEmpty
          ? defaultSectionOrder
          : order,
    );
  }

  Map<String, dynamic> toMap() => {
    'suggestionsEnabled': suggestionsEnabled,
    'freeDeliveryProgressEnabled': freeDeliveryProgressEnabled,
    'sectionOrder': sectionOrder,
  };

  CartUiSettings copyWith({
    bool? suggestionsEnabled,
    bool? freeDeliveryProgressEnabled,
    List<String>? sectionOrder,
  }) {
    return CartUiSettings(
      suggestionsEnabled: suggestionsEnabled ?? this.suggestionsEnabled,
      freeDeliveryProgressEnabled:
          freeDeliveryProgressEnabled ?? this.freeDeliveryProgressEnabled,
      sectionOrder: sectionOrder ?? this.sectionOrder,
    );
  }
}
