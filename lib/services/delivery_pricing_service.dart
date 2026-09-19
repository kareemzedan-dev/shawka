import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/delivery_pricing_tier.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/delivery_pricing_analytics_repository.dart';

class DeliveryQuote {
  const DeliveryQuote({
    required this.fee,
    required this.rawFee,
    required this.distanceKm,
    required this.etaMinutes,
    required this.isInZone,
    this.freeDeliveryApplied = false,
    this.blockedStoreName = '',
    this.outOfZoneMessage = '',
    this.storeBreakdown = const [],
    this.routes = const [],
  });

  final double fee;
  final double rawFee;
  final double distanceKm;
  final int etaMinutes;
  final bool isInZone;
  final bool freeDeliveryApplied;
  final String blockedStoreName;
  final String outOfZoneMessage;
  final List<StoreDeliveryQuoteLine> storeBreakdown;
  final List<DirectionsRoute> routes;

  static const outOfZoneMessageDefault =
      'نعتذر، هذا المتجر لا يدعم التوصيل إلى موقعك الحالي.';
}

/// تسعير التوصيل من مسافة الطريق (Google Directions) — بدون خط مستقيم.
class DeliveryPricingService {
  DeliveryPricingService({
    GoogleMapsApiService? maps,
    DeliveryPricingAnalyticsRepository? analytics,
  })  : _maps = maps ?? GoogleMapsApiService(),
        _analytics = analytics ?? DeliveryPricingAnalyticsRepository();

  final GoogleMapsApiService _maps;
  final DeliveryPricingAnalyticsRepository _analytics;

  static const _directionsTimeout = Duration(seconds: 18);

  Future<DeliveryQuote> quote({
    required DeliveryAddress customer,
    required List<Store> stores,
    required AppSettings settings,
    required double cartSubtotal,
    bool logAnalytics = true,
  }) async {
    if (!customer.hasCoordinates) {
      return const DeliveryQuote(
        fee: 0,
        rawFee: 0,
        distanceKm: 0,
        etaMinutes: 0,
        isInZone: false,
        outOfZoneMessage: 'حدّد عنوان توصيل صالح',
      );
    }

    if (stores.isEmpty) {
      return const DeliveryQuote(
        fee: 0,
        rawFee: 0,
        distanceKm: 0,
        etaMinutes: 0,
        isInZone: true,
      );
    }

    final breakdown = <StoreDeliveryQuoteLine>[];
    final routes = <DirectionsRoute>[];
    var maxDistanceKm = 0.0;
    var maxEta = 0;
    var totalRawFee = 0.0;
    String? blockedStore;

    for (final store in stores) {
      final origin = _storeOrigin(store, customer, settings);
      if (origin == null) {
        blockedStore = store.name;
        breakdown.add(
          StoreDeliveryQuoteLine(
            storeId: store.id,
            storeName: store.name,
            distanceKm: 0,
            fee: 0,
            isDeliverable: false,
          ),
        );
        continue;
      }

      DirectionsRoute route;
      try {
        route = await _maps
            .directions(
              origin: origin,
              destination: customer.latLng,
            )
            .timeout(_directionsTimeout);
        if (!route.isValid) {
          route = _estimateRoadRoute(origin, customer.latLng);
        }
      } catch (_) {
        route = _estimateRoadRoute(origin, customer.latLng);
      }

      routes.add(route);
      final roadKm = route.distanceKm;
      final tiers = store.pricingTiersFor(settings);
      final tierResult = DeliveryTierResult.resolve(
        roadDistanceKm: roadKm,
        tiers: tiers,
        maxRoadKm: settings.deliveryMaxRoadKm,
      );

      if (!tierResult.isDeliverable) {
        blockedStore = store.name;
        breakdown.add(
          StoreDeliveryQuoteLine(
            storeId: store.id,
            storeName: store.name,
            distanceKm: roadKm,
            fee: 0,
            isDeliverable: false,
          ),
        );
        continue;
      }

      if (roadKm > maxDistanceKm) maxDistanceKm = roadKm;
      if (route.durationMinutes > maxEta) maxEta = route.durationMinutes;
      totalRawFee += tierResult.fee;

      breakdown.add(
        StoreDeliveryQuoteLine(
          storeId: store.id,
          storeName: store.name,
          distanceKm: roadKm,
          fee: tierResult.fee,
          isDeliverable: true,
        ),
      );
    }

    if (blockedStore != null ||
        breakdown.any((line) => !line.isDeliverable)) {
      final name = blockedStore ?? breakdown.firstWhere((l) => !l.isDeliverable).storeName;
      final result = DeliveryQuote(
        fee: 0,
        rawFee: 0,
        distanceKm: double.parse(maxDistanceKm.toStringAsFixed(1)),
        etaMinutes: 0,
        isInZone: false,
        blockedStoreName: name,
        outOfZoneMessage: DeliveryQuote.outOfZoneMessageDefault,
        storeBreakdown: breakdown,
        routes: routes,
      );
      if (logAnalytics) {
        unawaited(
          _analytics.logQuote(
            distanceKm: result.distanceKm,
            fee: 0,
            isInZone: false,
            storeCount: stores.length,
            area: customer.area,
            governorate: customer.governorate,
            blockedStoreName: name,
          ),
        );
      }
      return result;
    }

    var fee = totalRawFee;
    var freeApplied = false;

    if (_qualifiesForFreeDelivery(
      stores: stores,
      settings: settings,
      cartSubtotal: cartSubtotal,
    )) {
      fee = 0;
      freeApplied = true;
    }

    final result = DeliveryQuote(
      fee: double.parse(fee.toStringAsFixed(2)),
      rawFee: double.parse(totalRawFee.toStringAsFixed(2)),
      distanceKm: double.parse(maxDistanceKm.toStringAsFixed(1)),
      etaMinutes: maxEta.clamp(5, 120),
      isInZone: true,
      freeDeliveryApplied: freeApplied,
      storeBreakdown: breakdown,
      routes: routes,
    );

    if (logAnalytics) {
      unawaited(
        _analytics.logQuote(
          distanceKm: result.distanceKm,
          fee: result.fee,
          isInZone: true,
          storeCount: stores.length,
          area: customer.area,
          governorate: customer.governorate,
          freeDelivery: freeApplied,
        ),
      );
    }

    return result;
  }

  DirectionsRoute _estimateRoadRoute(LatLng origin, LatLng destination) {
    final straightMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    final roadMeters = (straightMeters * 1.35).round().clamp(100, 500000);
    final durationSeconds = (roadMeters / 450 * 60).round().clamp(180, 7200);
    return DirectionsRoute(
      points: [origin, destination],
      distanceMeters: roadMeters,
      durationSeconds: durationSeconds,
    );
  }

  LatLng? _storeOrigin(
    Store store,
    DeliveryAddress customer,
    AppSettings settings,
  ) {
    if (store.hasLocation) {
      return LatLng(store.latitude!, store.longitude!);
    }

    final customerGov = customer.governorate.trim();
    final storeGov = store.governorate.trim();
    if (customerGov.isNotEmpty &&
        storeGov.isNotEmpty &&
        (customerGov == storeGov ||
            customerGov.contains(storeGov) ||
            storeGov.contains(customerGov))) {
      final id = EgyptGovernorates.byName(storeGov)?.id ?? 'cairo';
      final center = EgyptGovernorates.centerOf(id);
      return LatLng(center.lat, center.lng);
    }

    return LatLng(settings.deliveryZoneLat, settings.deliveryZoneLng);
  }

  bool _qualifiesForFreeDelivery({
    required List<Store> stores,
    required AppSettings settings,
    required double cartSubtotal,
  }) {
    if (stores.length == 1) {
      final store = stores.first;
      final threshold = store.freeDeliveryThresholdFor(settings);
      return threshold > 0 && cartSubtotal >= threshold;
    }
    return settings.qualifiesForFreeDelivery(cartSubtotal);
  }

  /// للتوافق — التحقق يتم عبر [quote] ومسافة الطريق.
  @Deprecated('Use quote() with Directions road distance instead.')
  bool isWithinDeliveryZone({
    required DeliveryAddress address,
    required AppSettings settings,
  }) {
    if (!address.hasCoordinates) return false;
    return true;
  }
}
