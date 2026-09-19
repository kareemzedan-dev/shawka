import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';

/// وضع عرض الخريطة حسب مرحلة التوصيل.
enum TrackingMapMode {
  /// قبل استلام المندوب للطلب — متجر + نقطة التوصيل.
  storeAndCustomer,

  /// بعد الاستلام / في الطريق — نقطة التوصيل + موتوسيكل المندوب.
  driverToCustomer,
}

/// لقطة تتبع — إحداثيات حقيقية + مسارات من Directions (خارجياً).
class OrderTrackingSnapshot {
  const OrderTrackingSnapshot({
    required this.customer,
    required this.store,
    required this.driver,
    required this.routePoints,
    required this.secondaryRoutePoints,
    required this.etaMinutes,
    required this.distanceKm,
    required this.statusBanner,
    required this.showDriver,
    required this.routeFromDriver,
    required this.driverProgress,
    this.mapMode = TrackingMapMode.storeAndCustomer,
    this.driverInfo,
    this.usesLiveDriverGps = false,
    this.hasRealCoordinates = false,
    this.storeLabel = 'المتجر',
  });

  final LatLng customer;
  final LatLng store;
  final LatLng driver;
  final List<LatLng> routePoints;
  final List<LatLng> secondaryRoutePoints;
  final int etaMinutes;
  final double distanceKm;
  final String statusBanner;
  final bool showDriver;
  final bool routeFromDriver;
  final double driverProgress;
  final TrackingMapMode mapMode;
  final TrackingDriverInfo? driverInfo;
  final bool usesLiveDriverGps;
  final bool hasRealCoordinates;
  final String storeLabel;

  bool get isLiveDeliveryMode =>
      mapMode == TrackingMapMode.driverToCustomer;

  OrderTrackingSnapshot copyWithRoutes({
    required List<LatLng> primary,
    List<LatLng>? secondary,
    int? etaMinutes,
    double? distanceKm,
  }) {
    return OrderTrackingSnapshot(
      customer: customer,
      store: store,
      driver: driver,
      routePoints: primary,
      secondaryRoutePoints: secondary ?? secondaryRoutePoints,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      statusBanner: statusBanner,
      showDriver: showDriver,
      routeFromDriver: routeFromDriver,
      driverProgress: driverProgress,
      mapMode: mapMode,
      driverInfo: driverInfo,
      usesLiveDriverGps: usesLiveDriverGps,
      hasRealCoordinates: hasRealCoordinates,
      storeLabel: storeLabel,
    );
  }
}

class TrackingDriverInfo {
  const TrackingDriverInfo({
    required this.name,
    required this.phone,
    required this.vehicleLabel,
    required this.rating,
    this.ratingCount = 0,
  });

  final String name;
  final String phone;
  final String vehicleLabel;
  final double rating;
  final int ratingCount;
}

abstract final class OrderTrackingUiData {
  static const _govCenters = <String, LatLng>{
    'القاهرة': LatLng(30.0444, 31.2357),
    'الجيزة': LatLng(30.0131, 31.2089),
    'الإسكندرية': LatLng(31.2001, 29.9187),
    'القليوبية': LatLng(30.3292, 31.2166),
  };

  static String statusBanner(OrderStatus status) => switch (status) {
        OrderStatus.pending => '🟠 طلبك قيد المراجعة',
        OrderStatus.preparing => '🔵 جاري تحضير طلبك',
        OrderStatus.readyForPickup => '🟢 طلبك جاهز للاستلام',
        OrderStatus.onTheWay => '🛵 خرج للتوصيل — المندوب في الطريق إليك',
        OrderStatus.delivered => '✅ تم تسليم الطلب',
        OrderStatus.cancelled => '🔴 تم إلغاء الطلب',
      };

  static String paymentLabel(Order order) => 'الدفع عند الاستلام';

  static OrderTrackingSnapshot build(
    Order order, {
    Store? storeDoc,
    AppUser? driver,
  }) {
    final seed = order.id.hashCode ^ order.storeId.hashCode;
    final center = _govCenters[order.governorate] ?? _govCenters['القاهرة']!;

    final store = _resolveStore(storeDoc, order, center, seed);
    final hasRealCustomer = order.hasDeliveryCoordinates;
    final customer = hasRealCustomer
        ? LatLng(order.addressLat!, order.addressLng!)
        : _offset(store, seed + 17, -0.009, 0.011);

    final onWay = order.status == OrderStatus.onTheWay;
    final delivered = order.status == OrderStatus.delivered;
    final ready = order.status == OrderStatus.readyForPickup;
    final preparing = order.status == OrderStatus.preparing;
    final hasAssignedDriver = order.hasAssignedDriver;
    final phase = (order.deliveryPhase ?? '').trim().toLowerCase();
    final pickedUp = order.deliveryPickedUpAt != null ||
        phase == 'picked_up' ||
        phase == 'in_transit' ||
        phase == 'to_customer' ||
        onWay;

    // وضع الخريطة: قبل الاستلام متجر+توصيل — بعده توصيل+مندوب متحرك.
    final mapMode = (pickedUp || delivered)
        ? TrackingMapMode.driverToCustomer
        : TrackingMapMode.storeAndCustomer;

    // يظهر المندوب على الخريطة عند التعيين، ويتحرك فعلياً بعد الاستلام.
    final showDriver = hasAssignedDriver &&
        (preparing || ready || onWay || delivered || pickedUp);

    final hasDriverCoords = driver != null &&
        driver.latitude != null &&
        driver.longitude != null;
    final usesFreshGps = hasDriverCoords &&
        driver.hasLiveLocation &&
        (pickedUp || ready || onWay || delivered);

    // Real GPS only — no simulated movement along the route.
    final LatLng driverPos;
    if (delivered) {
      driverPos = customer;
    } else if (hasDriverCoords && (pickedUp || ready || onWay)) {
      driverPos = LatLng(driver.latitude!, driver.longitude!);
    } else if (showDriver) {
      driverPos = store;
    } else {
      driverPos = store;
    }

    final progress = delivered
        ? 1.0
        : usesFreshGps
            ? _progressFromDriver(store, customer, driver)
            : ready
                ? 1.0
                : 0.0;

    final routeFromDriver = pickedUp || onWay || delivered;
    final routeStart = mapMode == TrackingMapMode.driverToCustomer
        ? driverPos
        : store;
    final routeEnd = customer;

    TrackingDriverInfo? driverInfo;
    if (hasAssignedDriver && order.status != OrderStatus.cancelled) {
      driverInfo = _buildDriverInfo(order, driver);
    }

    final straightKm = _distanceKm(routeStart, routeEnd);
    final etaMinutes = _etaMinutes(
      km: straightKm,
      status: order.status,
      store: store,
      customer: customer,
      driver: (pickedUp || onWay) && hasDriverCoords ? driverPos : null,
    );

    return OrderTrackingSnapshot(
      customer: customer,
      store: store,
      driver: driverPos,
      routePoints: const [],
      secondaryRoutePoints: const [],
      etaMinutes: etaMinutes,
      distanceKm: straightKm,
      statusBanner: statusBanner(order.status),
      showDriver: showDriver && mapMode == TrackingMapMode.driverToCustomer,
      routeFromDriver: routeFromDriver,
      driverProgress: progress,
      mapMode: mapMode,
      driverInfo: driverInfo,
      usesLiveDriverGps: usesFreshGps && mapMode == TrackingMapMode.driverToCustomer,
      hasRealCoordinates:
          hasRealCustomer ||
          (storeDoc?.latitude != null && storeDoc?.longitude != null),
      storeLabel: storeDoc?.name.trim().isNotEmpty == true
          ? storeDoc!.name.trim()
          : (order.storeName.trim().isNotEmpty ? order.storeName.trim() : 'المتجر'),
    );
  }

  static LatLng _resolveStore(
    Store? storeDoc,
    Order order,
    LatLng center,
    int seed,
  ) {
    if (storeDoc?.latitude != null && storeDoc?.longitude != null) {
      return LatLng(storeDoc!.latitude!, storeDoc.longitude!);
    }
    if (order.storeLat != null && order.storeLng != null) {
      return LatLng(order.storeLat!, order.storeLng!);
    }
    // مركز المحافظة الحقيقي — بدون إزاحة عشوائية مضلّلة.
    return center;
  }

  static double _progressFromDriver(
    LatLng store,
    LatLng customer,
    AppUser driver,
  ) {
    final d = LatLng(driver.latitude!, driver.longitude!);
    final total = _distanceKm(store, customer);
    if (total <= 0.01) return 0.5;
    final fromStore = _distanceKm(store, d);
    return (fromStore / total).clamp(0.05, 0.98);
  }

  static LatLng _offset(LatLng base, int seed, double dLat, double dLng) {
    final r = math.Random(seed);
    return LatLng(
      base.latitude + dLat * (0.6 + r.nextDouble()),
      base.longitude + dLng * (0.6 + r.nextDouble()),
    );
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const earthRadius = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return (earthRadius * c).clamp(0.4, 99.0);
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  static int _etaMinutes({
    required double km,
    required OrderStatus status,
    required LatLng store,
    required LatLng customer,
    LatLng? driver,
  }) {
    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      return 0;
    }
    if (status == OrderStatus.pending) return 0;

    const avgSpeedKmh = 25.0;
    const pickupBufferMinutes = 3;

    if (status == OrderStatus.preparing) {
      final storeToCustomerKm = _distanceKm(store, customer);
      final prepMinutes = 15;
      final deliveryMinutes =
          ((storeToCustomerKm / avgSpeedKmh) * 60).round().clamp(1, 90);
      return prepMinutes + deliveryMinutes;
    }

    if (status == OrderStatus.readyForPickup) {
      final storeToCustomerKm = _distanceKm(store, customer);
      return pickupBufferMinutes +
          ((storeToCustomerKm / avgSpeedKmh) * 60).round().clamp(1, 90);
    }

    if (status == OrderStatus.onTheWay && driver != null) {
      final driverToCustomerKm = _distanceKm(driver, customer);
      return ((driverToCustomerKm / avgSpeedKmh) * 60).round().clamp(1, 90);
    }

    return ((km / avgSpeedKmh) * 60).round().clamp(1, 90);
  }

  static TrackingDriverInfo? _buildDriverInfo(Order order, AppUser? driver) {
    final name = _firstNonEmpty([order.deliveryName, driver?.name]);
    final phone = _firstNonEmpty([order.deliveryPhone, driver?.phone]);
    if (name == null) return null;

    final rating = driver?.avgDriverRating ?? 0;
    return TrackingDriverInfo(
      name: name,
      phone: phone ?? '',
      vehicleLabel: vehicleLabel(
        vehicleType: driver?.vehicleType,
        fromOrder: order.deliveryVehicleType,
      ),
      rating: rating,
      ratingCount: driver?.driverRatingCount ?? 0,
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String vehicleLabel({String? vehicleType, String? fromOrder}) {
    final type = (fromOrder?.trim().isNotEmpty == true
            ? fromOrder!.trim()
            : vehicleType?.trim())
        ?.toLowerCase();
    return switch (type) {
      'bicycle' => '🚲 دراجة',
      'car' => '🚗 سيارة',
      'motorcycle' => '🛵 دراجة نارية',
      _ => '',
    };
  }
}
