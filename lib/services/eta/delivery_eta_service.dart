import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/services/analytics_service.dart';

/// Unified ETA — Google Directions when driver exists, Haversine fallback only.
class DeliveryEtaResult {
  const DeliveryEtaResult({
    required this.minutes,
    required this.distanceKm,
    required this.source,
  });

  final int minutes;
  final double distanceKm;
  final String source;
}

abstract final class DeliveryEtaService {
  static final _maps = GoogleMapsApiService();

  /// Before pickup: driver → store. After pickup / on the way: driver → customer.
  static Future<DeliveryEtaResult> estimate({
    required Order order,
    required LatLng driver,
    required LatLng store,
    required LatLng customer,
    String analyticsScreen = 'order_tracking',
  }) async {
    final pickedUp = order.deliveryPickedUpAt != null ||
        order.deliveryPhase == 'picked_up' ||
        order.deliveryPhase == 'outForDelivery' ||
        order.deliveryPhase == 'in_transit' ||
        order.status == OrderStatus.onTheWay;

    final destination = pickedUp ? customer : store;

    try {
      final route = await _maps.directions(origin: driver, destination: destination);
      if (route.isValid && route.durationMinutes > 0) {
        final result = DeliveryEtaResult(
          minutes: route.durationMinutes,
          distanceKm: double.parse(route.distanceKm.toStringAsFixed(1)),
          source: 'directions',
        );
        unawaited(_logSource(analyticsScreen, result.source, order.id));
        return result;
      }
    } catch (_) {
      /* fallback */
    }

    final km = _haversineKm(driver, destination);
    final minutes = _fallbackMinutes(km, order.status);
    final result = DeliveryEtaResult(
      minutes: minutes,
      distanceKm: double.parse(km.toStringAsFixed(1)),
      source: 'fallback',
    );
    unawaited(_logSource(analyticsScreen, result.source, order.id));
    return result;
  }

  static Future<void> _logSource(
    String screen,
    String source,
    String orderId,
  ) async {
    await AnalyticsService.instance.track(
      type: AnalyticsEventType.screenView,
      screen: screen,
      label: 'eta_computed',
      metadata: {'eta_source': source, 'orderId': orderId},
    );
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  static int _fallbackMinutes(double km, OrderStatus status) {
    final speed = status == OrderStatus.onTheWay ? 22.0 : 25.0;
    return math.max(1, (km / speed * 60).round());
  }

  static double _toRad(double deg) => deg * (math.pi / 180);
}
