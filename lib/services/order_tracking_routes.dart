import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/services/eta/delivery_eta_service.dart';

/// مسارات تتبع — ETA من Directions عند وجود مندوب، Haversine fallback فقط.
class OrderTrackingRouteBundle {
  const OrderTrackingRouteBundle({
    required this.primaryPoints,
    this.secondaryPoints = const [],
    required this.etaMinutes,
    required this.distanceKm,
    this.etaSource = 'fallback',
  });

  final List<LatLng> primaryPoints;
  final List<LatLng> secondaryPoints;
  final int etaMinutes;
  final double distanceKm;
  final String etaSource;

  static const empty = OrderTrackingRouteBundle(
    primaryPoints: [],
    etaMinutes: 0,
    distanceKm: 0,
  );
}

class OrderTrackingRoutesLoader {
  OrderTrackingRoutesLoader({GoogleMapsApiService? maps})
      : _maps = maps ?? GoogleMapsApiService();

  final GoogleMapsApiService _maps;

  Future<OrderTrackingRouteBundle> load({
    required Order order,
    required OrderTrackingSnapshot snapshot,
    Store? storeDoc,
    AppUser? driver,
  }) async {
    final store = snapshot.store;
    final customer = snapshot.customer;
    final driverPos = snapshot.driver;

    if (order.status == OrderStatus.delivered) {
      return const OrderTrackingRouteBundle(
        primaryPoints: [],
        etaMinutes: 0,
        distanceKm: 0,
      );
    }

    if (order.status == OrderStatus.pending ||
        order.status == OrderStatus.preparing ||
        (order.status == OrderStatus.readyForPickup &&
            !snapshot.isLiveDeliveryMode)) {
      return const OrderTrackingRouteBundle(
        primaryPoints: [],
        secondaryPoints: [],
        etaMinutes: 0,
        distanceKm: 0,
      );
    }

    final hasDriver =
        driver != null &&
        driver.latitude != null &&
        driver.longitude != null &&
        snapshot.showDriver;

    if (hasDriver) {
      try {
        final pickedUp = order.deliveryPickedUpAt != null ||
            order.deliveryPhase == 'picked_up' ||
            order.deliveryPhase == 'outForDelivery' ||
            order.deliveryPhase == 'in_transit' ||
            order.status == OrderStatus.onTheWay;

        final destination = pickedUp ? customer : store;
        final toDest = await _maps.directions(
          origin: driverPos,
          destination: destination,
        );

        DirectionsRoute? storeToDriver;
        if (pickedUp && storeDoc?.latitude != null) {
          storeToDriver = await _maps.directions(
            origin: store,
            destination: driverPos,
          );
        }

        final eta = await DeliveryEtaService.estimate(
          order: order,
          driver: driverPos,
          store: store,
          customer: customer,
        );

        return OrderTrackingRouteBundle(
          primaryPoints: toDest.isValid ? toDest.points : snapshot.routePoints,
          secondaryPoints: storeToDriver != null && storeToDriver.isValid
              ? storeToDriver.points
              : snapshot.secondaryRoutePoints,
          etaMinutes: eta.minutes,
          distanceKm: eta.distanceKm,
          etaSource: eta.source,
        );
      } catch (_) {
        /* fallback below */
      }
    }

    return OrderTrackingRouteBundle(
      primaryPoints: snapshot.routePoints,
      secondaryPoints: snapshot.secondaryRoutePoints,
      etaMinutes: snapshot.etaMinutes,
      distanceKm: snapshot.distanceKm,
      etaSource: 'fallback',
    );
  }
}
