import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/order.dart';

class AdminAnalyticsSnapshot {
  const AdminAnalyticsSnapshot({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.averageOrderValue,
    required this.customersCount,
    required this.openStoresCount,
    required this.ordersToday,
    required this.ordersThisMonth,
    required this.revenueByDay,
    required this.topStores,
    required this.topProducts,
    required this.conversionRate,
  });

  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double revenue;
  final double averageOrderValue;
  final int customersCount;
  final int openStoresCount;
  final int ordersToday;
  final int ordersThisMonth;
  final List<AdminDailyMetric> revenueByDay;
  final List<AdminRankedItem> topStores;
  final List<AdminRankedItem> topProducts;
  final double conversionRate;
}

class AdminDailyMetric {
  const AdminDailyMetric({required this.day, required this.value});
  final DateTime day;
  final double value;
}

class AdminRankedItem {
  const AdminRankedItem({required this.label, required this.value});
  final String label;
  final double value;
}

abstract final class AdminAnalyticsCalculator {
  static AdminAnalyticsSnapshot compute({
    required List<Order> orders,
    required int customersCount,
    required int openStoresCount,
    required int checkoutStarts,
    required int orderPlacedEvents,
    List<AnalyticsEvent> events = const [],
    Set<String> governorateStoreIds = const {},
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final completed = orders
        .where((o) => o.status == OrderStatus.delivered)
        .toList();
    final cancelled =
        orders.where((o) => o.status == OrderStatus.cancelled).length;
    final active = orders.where((o) => o.status.isActive).length;
    final revenue = completed.fold<double>(0, (sum, o) => sum + o.grandTotal);
    final ordersToday = orders
        .where((o) => !o.createdAt.isBefore(todayStart))
        .length;
    final ordersThisMonth = orders
        .where((o) => !o.createdAt.isBefore(monthStart))
        .length;

    final revenueByDay = <AdminDailyMetric>[];
    for (var i = 6; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final dayRevenue = completed
          .where(
            (o) =>
                !o.createdAt.isBefore(day) && o.createdAt.isBefore(next),
          )
          .fold<double>(0, (sum, o) => sum + o.grandTotal);
      revenueByDay.add(AdminDailyMetric(day: day, value: dayRevenue));
    }

    final storeTotals = <String, double>{};
    for (final order in completed) {
      storeTotals[order.storeName] =
          (storeTotals[order.storeName] ?? 0) + order.grandTotal;
    }
    final topStores = storeTotals.entries
        .map((e) => AdminRankedItem(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = _computeTopProducts(
      completedOrders: completed,
      events: events,
      governorateStoreIds: governorateStoreIds,
    );

    final conversion = checkoutStarts <= 0
        ? 0.0
        : (orderPlacedEvents / checkoutStarts).clamp(0.0, 1.0);

    return AdminAnalyticsSnapshot(
      totalOrders: orders.length,
      activeOrders: active,
      completedOrders: completed.length,
      cancelledOrders: cancelled,
      revenue: revenue,
      averageOrderValue:
          completed.isEmpty ? 0 : revenue / completed.length,
      customersCount: customersCount,
      openStoresCount: openStoresCount,
      ordersToday: ordersToday,
      ordersThisMonth: ordersThisMonth,
      revenueByDay: revenueByDay,
      topStores: topStores.take(8).toList(),
      topProducts: topProducts.take(8).toList(),
      conversionRate: conversion,
    );
  }

  static List<AdminRankedItem> _computeTopProducts({
    required List<Order> completedOrders,
    required List<AnalyticsEvent> events,
    required Set<String> governorateStoreIds,
  }) {
    final counts = <String, double>{};

    void addProduct(String name, {int qty = 1}) {
      final key = name.trim();
      if (key.isEmpty) return;
      counts[key] = (counts[key] ?? 0) + qty;
    }

    for (final order in completedOrders) {
      if (order.lineItems.isNotEmpty) {
        for (final line in order.lineItems) {
          addProduct(line.productName, qty: line.quantity);
        }
      } else {
        for (final part in order.itemsSummary.split('،')) {
          addProduct(part);
        }
      }
    }

    final scopedEvents = governorateStoreIds.isEmpty
        ? events
        : events.where(
            (e) =>
                e.storeId.isEmpty ||
                governorateStoreIds.contains(e.storeId),
          );

    for (final e in scopedEvents) {
      if (e.type == AnalyticsEventType.addToCart &&
          e.productName.trim().isNotEmpty) {
        addProduct(e.productName);
      }
    }

    return counts.entries
        .map((e) => AdminRankedItem(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
