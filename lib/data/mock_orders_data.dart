import 'package:flutter/material.dart';
import 'package:matlobgo/models/app_notification.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';

abstract final class MockOrdersData {
  static final orders = [
    Order(
      id: 'ORD-1042',
      storeName: 'شركة النيل للتموين',
      category: 'supplier',
      itemsSummary: 'أرز بسمتي، زيت ذرة',
      itemCount: 2,
      total: 850,
      deliveryFee: 25,
      status: OrderStatus.onTheWay,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    Order(
      id: 'ORD-1038',
      storeName: 'مورد الزيوت المتحدة',
      category: 'supplier',
      itemsSummary: 'زيت دوار الشمس، سمنة',
      itemCount: 2,
      total: 1200,
      deliveryFee: 20,
      status: OrderStatus.readyForPickup,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Order(
      id: 'ORD-1025',
      storeName: 'شركة الدلتا للألبان',
      category: 'supplier',
      itemsSummary: 'جبنة شيدر، لبن كامل الدسم',
      itemCount: 5,
      total: 2450,
      deliveryFee: 18,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Order(
      id: 'ORD-1011',
      storeName: 'شركة الشرق للحوم',
      category: 'supplier',
      itemsSummary: 'لحم بقري مبرّد',
      itemCount: 1,
      total: 1650,
      deliveryFee: 30,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}

abstract final class MockProductsData {
  static const _catalog = {
    '1': [
      ('p1', 'أرز بسمتي كيس 25 كجم', 450.0),
      ('p2', 'سكر أبيض كيس 50 كجم', 850.0),
      ('p3', 'مكرونة عبوة جملة', 220.0),
    ],
    '2': [
      ('p4', 'زيت ذرة جالون', 320.0),
      ('p5', 'سمنة نباتية', 180.0),
    ],
    '3': [
      ('p6', 'جبنة بيضاء طبلية', 95.0),
      ('p7', 'لبن كامل الدسم كرتونة', 280.0),
      ('p8', 'زبادي علب جملة', 150.0),
    ],
    '4': [
      ('p9', 'صينية طماطم', 75.0),
      ('p10', 'صينية خيار', 65.0),
    ],
    '5': [
      ('p11', 'لحم بقري مبرّد كجم', 320.0),
      ('p12', 'دجاج مجمد كرتونة', 480.0),
    ],
    '6': [
      ('p13', 'دقيق فاخر كيس 50 كجم', 420.0),
      ('p14', 'خميرة فورية كرتونة', 95.0),
    ],
  };

  static List<Product> forStore(Store store) {
    final items = _catalog[store.id] ?? _defaultFor(store);
    return items
        .map(
          (e) => Product(
            id: e.$1,
            storeId: store.id,
            name: e.$2,
            price: e.$3,
          ),
        )
        .toList();
  }

  static List<(String, String, double)> _defaultFor(Store store) {
    return [
      ('d1', 'منتج جملة مميز', 175.0),
      ('d2', 'منتج إضافي', 85.0),
    ];
  }
}

abstract final class MockNotificationsData {
  static final notifications = [
    AppNotification(
      id: 'n1',
      title: 'طلبك في الطريق 🛵',
      body: 'طلب #ORD-1042 من شركة النيل للتموين في الطريق إليك',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      icon: Icons.delivery_dining_rounded,
    ),
    AppNotification(
      id: 'n2',
      title: 'عرض حصري',
      body: 'توصيل مجاني على أول 3 طلبات جملة — استخدم الكود SHAWKA3',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.local_offer_rounded,
    ),
    AppNotification(
      id: 'n3',
      title: 'تم تأكيد طلبك',
      body: 'مورد الزيوت المتحدة بدأ تجهيز طلبك #ORD-1038',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
      icon: Icons.check_circle_outline_rounded,
    ),
    AppNotification(
      id: 'n4',
      title: 'موردون جدد في منطقتك',
      body: 'اكتشف شركات توريد مواد غذائية جديدة في القاهرة',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      icon: Icons.storefront_rounded,
    ),
  ];
}
