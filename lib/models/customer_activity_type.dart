import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// نوع نشاط العميل (كافيه / مطعم / …) — يُدار من لوحة التحكم.
class CustomerActivityType {
  const CustomerActivityType({
    required this.id,
    required this.name,
    this.iconKey = 'store',
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String iconKey;
  final int sortOrder;
  final bool isActive;

  IconData get icon => activityTypeIcon(iconKey);

  factory CustomerActivityType.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      CustomerActivityType.fromMap(id: doc.id, data: doc.data() ?? const {});

  factory CustomerActivityType.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return CustomerActivityType(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      iconKey: (data['iconKey'] as String? ?? 'store').trim().isEmpty
          ? 'store'
          : (data['iconKey'] as String).trim(),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.trim(),
      'iconKey': iconKey,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CustomerActivityType copyWith({
    String? name,
    String? iconKey,
    int? sortOrder,
    bool? isActive,
  }) {
    return CustomerActivityType(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

IconData activityTypeIcon(String key) {
  return switch (key) {
    'cafe' || 'coffee' => Icons.local_cafe_rounded,
    'restaurant' || 'food' => Icons.restaurant_rounded,
    'hypermarket' || 'market' || 'supermarket' => Icons.local_mall_rounded,
    'hotel' => Icons.hotel_rounded,
    'bakery' => Icons.bakery_dining_rounded,
    'pharmacy' => Icons.local_pharmacy_rounded,
    'grocery' => Icons.storefront_rounded,
    _ => Icons.store_rounded,
  };
}

/// أيقونات اختيارية في نموذج الأدمن.
const List<(String key, String label)> kActivityTypeIconOptions = [
  ('cafe', 'كافيه'),
  ('restaurant', 'مطعم'),
  ('hypermarket', 'هايبر / مول'),
  ('hotel', 'فندق'),
  ('bakery', 'مخبز'),
  ('pharmacy', 'صيدلية'),
  ('grocery', 'بقالة'),
  ('store', 'متجر عام'),
];

/// البذور الافتراضية عند أول فتح للوحة التحكم.
abstract final class CustomerActivityTypeDefaults {
  static const List<CustomerActivityType> entries = [
    CustomerActivityType(
      id: 'cafe',
      name: 'كافيه',
      iconKey: 'cafe',
      sortOrder: 0,
    ),
    CustomerActivityType(
      id: 'restaurant',
      name: 'مطعم',
      iconKey: 'restaurant',
      sortOrder: 1,
    ),
    CustomerActivityType(
      id: 'hypermarket',
      name: 'هايبر ماركت',
      iconKey: 'hypermarket',
      sortOrder: 2,
    ),
    CustomerActivityType(
      id: 'hotel',
      name: 'فندق',
      iconKey: 'hotel',
      sortOrder: 3,
    ),
  ];
}
