import 'package:cloud_firestore/cloud_firestore.dart';

enum PromotionType { percent, fixedAmount, freeDelivery }

extension PromotionTypeX on PromotionType {
  String get firestoreValue => name;

  String get label => switch (this) {
    PromotionType.percent => 'خصم نسبة',
    PromotionType.fixedAmount => 'خصم مبلغ',
    PromotionType.freeDelivery => 'توصيل مجاني',
  };

  static PromotionType fromFirestore(String? value) {
    return PromotionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PromotionType.percent,
    );
  }
}

class Promotion {
  const Promotion({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.value,
    required this.governorate,
    this.storeId = '',
    this.storeName = '',
    required this.isActive,
    required this.startsAt,
    required this.endsAt,
    required this.sortOrder,
    this.minOrderAmount = 0,
    this.maxDiscount = 0,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.perUserLimit = 0,
    this.governorates = const [],
    this.storeIds = const [],
    this.categoryIds = const [],
    this.productIds = const [],
  });

  final String id;
  final String code;
  final String title;
  final PromotionType type;
  final double value;
  final String governorate;
  final String storeId;
  final String storeName;
  final bool isActive;
  final DateTime startsAt;
  final DateTime endsAt;
  final int sortOrder;
  final double minOrderAmount;
  final double maxDiscount;
  final int usageLimit;
  final int usageCount;
  final int perUserLimit;
  final List<String> governorates;
  final List<String> storeIds;
  final List<String> categoryIds;
  final List<String> productIds;

  bool get isValidNow {
    final now = DateTime.now();
    return isActive && !now.isBefore(startsAt) && !now.isAfter(endsAt);
  }

  double discountFor(double subtotal) {
    if (subtotal < minOrderAmount) return 0;
    return switch (type) {
      PromotionType.percent => (subtotal * value / 100).clamp(
        0,
        subtotal * 0.5,
      ),
      PromotionType.fixedAmount => value.clamp(0, subtotal),
      PromotionType.freeDelivery => 0,
    };
  }

  factory Promotion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Promotion(
      id: doc.id,
      code: (data['code'] as String? ?? '').toUpperCase(),
      title: data['title'] as String? ?? '',
      type: PromotionTypeX.fromFirestore(data['type'] as String?),
      value: (data['value'] as num?)?.toDouble() ?? 0,
      governorate: data['governorate'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      startsAt:
          (data['startsAt'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 1)),
      endsAt:
          (data['endsAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      sortOrder: data['sortOrder'] as int? ?? 0,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble() ?? 0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble() ?? 0,
      usageLimit: (data['usageLimit'] as num?)?.toInt() ?? 0,
      usageCount: (data['usageCount'] as num?)?.toInt() ?? 0,
      perUserLimit: (data['perUserLimit'] as num?)?.toInt() ?? 0,
      governorates: List<String>.from(
        data['governorates'] as List? ?? const [],
      ),
      storeIds: List<String>.from(data['storeIds'] as List? ?? const []),
      categoryIds: List<String>.from(data['categoryIds'] as List? ?? const []),
      productIds: List<String>.from(data['productIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code.toUpperCase(),
      'title': title,
      'type': type.firestoreValue,
      'value': value,
      'governorate': governorate,
      'storeId': storeId,
      'storeName': storeName,
      'isActive': isActive,
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'sortOrder': sortOrder,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'perUserLimit': perUserLimit,
      'governorates': governorates,
      'storeIds': storeIds,
      'categoryIds': categoryIds,
      'productIds': productIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Promotion copyWith({
    String? id,
    String? code,
    String? title,
    PromotionType? type,
    double? value,
    String? governorate,
    String? storeId,
    String? storeName,
    bool? isActive,
    DateTime? startsAt,
    DateTime? endsAt,
    int? sortOrder,
    double? minOrderAmount,
    double? maxDiscount,
    int? usageLimit,
    int? usageCount,
    int? perUserLimit,
    List<String>? governorates,
    List<String>? storeIds,
    List<String>? categoryIds,
    List<String>? productIds,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      type: type ?? this.type,
      value: value ?? this.value,
      governorate: governorate ?? this.governorate,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      isActive: isActive ?? this.isActive,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      sortOrder: sortOrder ?? this.sortOrder,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      governorates: governorates ?? this.governorates,
      storeIds: storeIds ?? this.storeIds,
      categoryIds: categoryIds ?? this.categoryIds,
      productIds: productIds ?? this.productIds,
    );
  }
}
