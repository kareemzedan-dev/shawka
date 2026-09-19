import 'package:matlobgo/models/store.dart';

/// أقسام الرئيسية — نفس منطق تطبيق الموبايل + بيانات Firestore الحقيقية.
abstract final class WebStoreSections {
  static List<Store> openOnly(List<Store> stores) =>
      stores.where((s) => s.isOpen).toList();

  /// مطابق لـ home_screen._featuredStores
  static List<Store> featured(List<Store> stores) =>
      stores.where((s) => s.isFeatured && s.isOpen).toList();

  /// مطابق لـ home_screen._trendingStores
  static List<Store> trendingNow(List<Store> stores) {
    final featuredIds =
        featured(stores).map((s) => s.id).toSet();
    final list = stores
        .where((s) => s.isOpen && !featuredIds.contains(s.id))
        .where((s) => s.rating >= 4.5)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(8).toList();
  }

  static List<Store> topRated(List<Store> stores) =>
      openOnly(stores).toList()..sort((a, b) => b.rating.compareTo(a.rating));

  static List<Store> fastest(List<Store> stores) =>
      openOnly(stores).toList()
        ..sort((a, b) => a.deliveryMinutes.compareTo(b.deliveryMinutes));

  static List<Store> withOffers(List<Store> stores) => openOnly(stores)
      .where((s) => s.discountLabel != null && s.discountLabel!.isNotEmpty)
      .toList();

  /// متاجر غير مميزة — الأعلى تقييماً بين الجديدة على المنصة
  static List<Store> newJoiners(List<Store> stores) {
    final list = openOnly(stores).where((s) => !s.isFeatured).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(8).toList();
  }

  static List<Store> nearby(List<Store> stores) => openOnly(stores);

  static List<Store> recommended(List<Store> stores) {
    final scored = openOnly(stores).map((s) {
      final score = s.rating * 2 +
          (s.isFeatured ? 1.5 : 0) +
          (40 - s.deliveryMinutes.clamp(0, 40)) / 20 +
          ((s.discountLabel?.isNotEmpty ?? false) ? 0.5 : 0);
      return MapEntry(s, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(10).toList();
  }
}
