class CheckoutPaymentMethod {
  const CheckoutPaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.sortOrder,
    this.logoUrl = '',
    this.feeFixed = 0,
    this.feePercent = 0,
    this.governorates = const [],
    this.storeIds = const [],
    this.categoryIds = const [],
    this.minOrderAmount = 0,
    this.maxOrderAmount = 0,
    this.unavailableReason = '',
  });

  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final bool isActive;
  final int sortOrder;
  final double feeFixed;
  final double feePercent;
  final List<String> governorates;
  final List<String> storeIds;
  final List<String> categoryIds;
  final double minOrderAmount;
  final double maxOrderAmount;
  final String unavailableReason;

  factory CheckoutPaymentMethod.fromMap(Map<String, dynamic> map) {
    return CheckoutPaymentMethod(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      feeFixed: (map['feeFixed'] as num?)?.toDouble() ?? 0,
      feePercent: (map['feePercent'] as num?)?.toDouble() ?? 0,
      governorates: List<String>.from(map['governorates'] as List? ?? const []),
      storeIds: List<String>.from(map['storeIds'] as List? ?? const []),
      categoryIds: List<String>.from(map['categoryIds'] as List? ?? const []),
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0,
      maxOrderAmount: (map['maxOrderAmount'] as num?)?.toDouble() ?? 0,
      unavailableReason: map['unavailableReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'logoUrl': logoUrl,
    'isActive': isActive,
    'sortOrder': sortOrder,
    'feeFixed': feeFixed,
    'feePercent': feePercent,
    'governorates': governorates,
    'storeIds': storeIds,
    'categoryIds': categoryIds,
    'minOrderAmount': minOrderAmount,
    'maxOrderAmount': maxOrderAmount,
    'unavailableReason': unavailableReason,
  };

  CheckoutPaymentMethod copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    bool? isActive,
    int? sortOrder,
    double? feeFixed,
    double? feePercent,
    List<String>? governorates,
    List<String>? storeIds,
    List<String>? categoryIds,
    double? minOrderAmount,
    double? maxOrderAmount,
    String? unavailableReason,
  }) {
    return CheckoutPaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      feeFixed: feeFixed ?? this.feeFixed,
      feePercent: feePercent ?? this.feePercent,
      governorates: governorates ?? this.governorates,
      storeIds: storeIds ?? this.storeIds,
      categoryIds: categoryIds ?? this.categoryIds,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxOrderAmount: maxOrderAmount ?? this.maxOrderAmount,
      unavailableReason: unavailableReason ?? this.unavailableReason,
    );
  }
}
