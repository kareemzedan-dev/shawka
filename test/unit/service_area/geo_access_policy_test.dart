import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/geo/geo_access_policy.dart';
import 'package:matlobgo/services/delivery_pricing_service.dart';

/// مرآة لمنطق CartService.validateDeliveryAddress بدون اعتماد على Session.
String? _localCheckoutGate({
  required bool hasAddress,
  required bool hasCoordinates,
  required bool isInZone,
  String outOfZoneMessage = '',
}) {
  if (!hasAddress || !hasCoordinates) {
    return 'حدّد عنوان توصيل صالح من الخريطة أو البحث';
  }
  if (!isInZone) {
    return outOfZoneMessage.isNotEmpty
        ? outOfZoneMessage
        : DeliveryQuote.outOfZoneMessageDefault;
  }
  return null;
}

void main() {
  group('App Access — no geo startup block', () {
    test('egyptSupported → browse allowed', () {
      const ctx = UserGeoContext.egyptSupported;
      expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
      expect(GeoAccessPolicy.allowsAppBrowsing(ctx), isTrue);
      expect(GeoAccessPolicy.hasActiveLocalDelivery(ctx), isTrue);
      expect(GeoAccessPolicy.usesBrowsingFallback(ctx), isFalse);
    });

    test('egyptUnsupported → browse allowed (no full-app block)', () {
      const ctx = UserGeoContext.egyptUnsupported;
      expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
      expect(GeoAccessPolicy.allowsAppBrowsing(ctx), isTrue);
      expect(GeoAccessPolicy.hasActiveLocalDelivery(ctx), isFalse);
      expect(GeoAccessPolicy.usesBrowsingFallback(ctx), isTrue);
    });

    test('outsideEgypt → browse allowed', () {
      const ctx = UserGeoContext.outsideEgypt;
      expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
      expect(GeoAccessPolicy.allowsAppBrowsing(ctx), isTrue);
      expect(GeoAccessPolicy.usesBrowsingFallback(ctx), isTrue);
    });

    test('unknown → browse allowed', () {
      const ctx = UserGeoContext.unknown;
      expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
      expect(GeoAccessPolicy.allowsAppBrowsing(ctx), isTrue);
      expect(GeoAccessPolicy.usesBrowsingFallback(ctx), isTrue);
    });

    test('no geo state results in startup full block', () {
      for (final ctx in UserGeoContext.values) {
        expect(
          GeoAccessPolicy.blocksAppAccess(ctx),
          isFalse,
          reason: '$ctx must never block app access',
        );
      }
    });
  });

  group('GeoAccessPolicy.resolve', () {
    test('Egypt + supported governorate', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'EG',
          hasCoordinates: true,
          coordinatesInEgyptBounds: true,
          matchedEgyptianGovernorate: true,
          matchedGovernorateAvailable: true,
        ),
      );
      expect(ctx, UserGeoContext.egyptSupported);
    });

    test('Egypt + unsupported governorate resolves egyptUnsupported', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'EG',
          hasCoordinates: true,
          coordinatesInEgyptBounds: true,
          matchedEgyptianGovernorate: true,
          matchedGovernorateAvailable: false,
        ),
      );
      expect(ctx, UserGeoContext.egyptUnsupported);
      expect(GeoAccessPolicy.usesBrowsingFallback(ctx), isTrue);
    });

    test('Saudi Arabia → outsideEgypt browsable', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'SA',
          hasCoordinates: true,
          coordinatesInEgyptBounds: false,
        ),
      );
      expect(ctx, UserGeoContext.outsideEgypt);
      expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
    });

    test('United States → outsideEgypt browsable', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'US',
          hasCoordinates: true,
          coordinatesInEgyptBounds: false,
        ),
      );
      expect(ctx, UserGeoContext.outsideEgypt);
    });

    test('Europe → outsideEgypt browsable', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'GB',
          hasCoordinates: true,
          coordinatesInEgyptBounds: false,
        ),
      );
      expect(ctx, UserGeoContext.outsideEgypt);
    });

    test('permission denied / no coords → unknown browsable', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(hasCoordinates: false),
      );
      expect(ctx, UserGeoContext.unknown);
      expect(GeoAccessPolicy.allowsAppBrowsing(ctx), isTrue);
    });

    test(
      'services disabled / timeout / geocode failure → unknown browsable',
      () {
        final ctx = GeoAccessPolicy.resolve(const GeoResolutionInput());
        expect(ctx, UserGeoContext.unknown);
        expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
      },
    );

    test('coords outside Egypt without country → outsideEgypt', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          hasCoordinates: true,
          coordinatesInEgyptBounds: false,
        ),
      );
      expect(ctx, UserGeoContext.outsideEgypt);
    });

    test('coords inside Egypt without match → egyptUnsupported browsable', () {
      final ctx = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          hasCoordinates: true,
          coordinatesInEgyptBounds: true,
        ),
      );
      expect(ctx, UserGeoContext.egyptUnsupported);
      expect(GeoAccessPolicy.blocksAppAccess(ctx), isFalse);
    });
  });

  group('Browsing catalog fallback semantics', () {
    test('egyptUnsupported gets browsing fallback', () {
      expect(
        GeoAccessPolicy.usesBrowsingFallback(UserGeoContext.egyptUnsupported),
        isTrue,
      );
    });

    test('outsideEgypt gets browsing fallback', () {
      expect(
        GeoAccessPolicy.usesBrowsingFallback(UserGeoContext.outsideEgypt),
        isTrue,
      );
    });

    test('unknown gets browsing fallback', () {
      expect(
        GeoAccessPolicy.usesBrowsingFallback(UserGeoContext.unknown),
        isTrue,
      );
    });

    test('egyptSupported does not use browsing fallback', () {
      expect(
        GeoAccessPolicy.usesBrowsingFallback(UserGeoContext.egyptSupported),
        isFalse,
      );
    });
  });

  group('Checkout serviceability remains authoritative', () {
    test('foreign delivery address rejected', () {
      expect(
        GeoAccessPolicy.allowsAppBrowsing(UserGeoContext.outsideEgypt),
        isTrue,
      );
      final error = _localCheckoutGate(
        hasAddress: true,
        hasCoordinates: true,
        isInZone: false,
        outOfZoneMessage: 'خارج نطاق التوصيل',
      );
      expect(error, 'خارج نطاق التوصيل');
    });

    test('unsupported Egyptian address rejected', () {
      expect(
        GeoAccessPolicy.allowsAppBrowsing(UserGeoContext.egyptUnsupported),
        isTrue,
      );
      final error = _localCheckoutGate(
        hasAddress: true,
        hasCoordinates: true,
        isInZone: false,
      );
      expect(error, DeliveryQuote.outOfZoneMessageDefault);
    });

    test('supported Egyptian address passes local gate', () {
      final error = _localCheckoutGate(
        hasAddress: true,
        hasCoordinates: true,
        isInZone: true,
      );
      expect(error, isNull);
    });

    test('missing address rejected even when browsing allowed', () {
      final error = _localCheckoutGate(
        hasAddress: false,
        hasCoordinates: false,
        isInZone: true,
      );
      expect(error, isNotNull);
    });
  });

  group('Cache freshness', () {
    test('cached Egypt → fresh outside context works', () {
      final fresh = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'SA',
          hasCoordinates: true,
          coordinatesInEgyptBounds: false,
        ),
      );
      expect(fresh, UserGeoContext.outsideEgypt);
      expect(GeoAccessPolicy.blocksAppAccess(fresh), isFalse);
    });

    test('cached outside → fresh Egypt supported works', () {
      final fresh = GeoAccessPolicy.resolve(
        const GeoResolutionInput(
          countryCode: 'EG',
          hasCoordinates: true,
          coordinatesInEgyptBounds: true,
          matchedEgyptianGovernorate: true,
          matchedGovernorateAvailable: true,
        ),
      );
      expect(fresh, UserGeoContext.egyptSupported);
      expect(GeoAccessPolicy.hasActiveLocalDelivery(fresh), isTrue);
    });
  });
}
