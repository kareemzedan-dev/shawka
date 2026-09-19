import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/data/service_area_governorate_matcher.dart';
import 'package:matlobgo/core/geo/geo_access_policy.dart';
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:matlobgo/core/services/location_service.dart';
import 'package:matlobgo/core/services/ip_geolocation_service.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/governorate_repository.dart';
import 'package:matlobgo/models/zone.dart';
import 'package:matlobgo/repositories/service_area_analytics_repository.dart';
import 'package:matlobgo/repositories/zone_repository.dart';
import 'package:matlobgo/core/utils/startup_timing.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/delivery_address_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServiceAreaPhase {
  idle,
  detecting,
  supported,
  unsupported,

  /// تصفح الكتالوج بدون بوابة جغرافية (خارج مصر / غير معروف).
  browsing,
  error,
}

enum ServiceAreaErrorKind {
  none,
  permissionDenied,
  permissionDeniedForever,
  locationDisabled,
  offline,
  unknown,
}

/// تحديد المحافظة تلقائياً + التحقق من نطاق الخدمة + التخزين المحلي.
///
/// يفصل App Access عن Delivery Serviceability:
/// - داخل مصر غير المدعومة → حظر الدخول (UX الحالي).
/// - خارج مصر / Unknown → تصفح كامل بدون Startup Geo Block.
/// - التحقق من التوصيل يبقى عند Checkout/Backend.
class ServiceAreaService extends ChangeNotifier {
  ServiceAreaService._();

  static final ServiceAreaService instance = ServiceAreaService._();

  static const _keyOnboardingComplete = 'service_area_onboarding_done';
  static const _keyGovernorateId = 'service_area_governorate_id';
  static const _keyManualOverride = 'service_area_manual_override';
  static const _keyCity = 'service_area_city';
  static const _keyArea = 'service_area_area';
  static const _keyLat = 'service_area_lat';
  static const _keyLng = 'service_area_lng';
  static const _keyUnsupportedName = 'service_area_unsupported_name';
  static const _keyZoneId = 'service_area_zone_id';
  static const _keyZoneName = 'service_area_zone_name';
  static const _keyGeoContext = 'service_area_geo_context';
  static const _keyCountryCode = 'service_area_country_code';
  static const _keyBrowsingFallback = 'service_area_browsing_fallback';

  final _location = LocationService.instance;
  final _maps = GoogleMapsApiService();
  final _analytics = ServiceAreaAnalyticsRepository();
  final _governorateRepo = GovernorateRepository();
  final _zoneRepo = ZoneRepository();

  StreamSubscription<List<Governorate>>? _govSub;
  SharedPreferences? _prefs;

  bool _initialized = false;
  bool _onboardingComplete = false;
  bool _isManualOverride = false;
  ServiceAreaPhase _phase = ServiceAreaPhase.idle;
  ServiceAreaErrorKind _errorKind = ServiceAreaErrorKind.none;
  String _friendlyError = '';
  UserGeoContext _geoContext = UserGeoContext.unknown;
  String _countryCode = '';
  bool _browsingFallback = false;

  Governorate? _governorate;
  String _unsupportedName = '';
  String _city = '';
  String _area = '';
  double? _latitude;
  double? _longitude;
  List<Governorate> _catalog = EgyptGovernorates.all;
  bool _backgroundRefreshRunning = false;
  ServiceZone? _matchedZone;
  List<ServiceZone> _activeZones = [];

  /// يمكن الدخول فوراً: محافظة مدعومة أو وضع تصفح (خارج مصر / غير معروف).
  bool get canEnterAppImmediately =>
      _onboardingComplete &&
      !isBlocked &&
      (_governorate != null || _browsingFallback);

  bool get isBackgroundRefreshing => _backgroundRefreshRunning;
  bool get isInitialized => _initialized;
  bool get onboardingComplete => _onboardingComplete;
  bool get isManualOverride => _isManualOverride;
  ServiceAreaPhase get phase => _phase;
  ServiceAreaErrorKind get errorKind => _errorKind;
  String get friendlyError => _friendlyError;
  UserGeoContext get geoContext => _geoContext;
  String get countryCode => _countryCode;
  bool get isBrowsingFallback => _browsingFallback;
  Governorate? get governorate => _governorate;
  String get unsupportedName => _unsupportedName;
  String get city => _city;
  String get area => _area;
  LatLng? get coordinates => _latitude != null && _longitude != null
      ? LatLng(_latitude!, _longitude!)
      : null;

  ServiceZone? get matchedZone => _matchedZone;
  List<ServiceZone> get activeZonesInGovernorate => _activeZones;

  /// تسمية العرض (منطقة ثم مدينة ثم محافظة) — للعرض فقط وليس للتغيير.
  String get locationLabel {
    if (_browsingFallback) {
      return 'تصفح المتاجر';
    }
    final zoneName = _matchedZone?.name.trim() ?? '';
    if (zoneName.isNotEmpty) return zoneName;
    final areaName = _area.trim();
    if (areaName.isNotEmpty) return areaName;
    return _governorate?.name ?? 'موقعك';
  }

  bool get hasActiveGovernorate => _governorate != null;
  bool get isSupported =>
      _geoContext == UserGeoContext.egyptSupported &&
      _governorate != null &&
      _governorate!.isAvailable &&
      _phase == ServiceAreaPhase.supported;

  /// تسمية قديمة: لم يعد أي Geo Context يحظر فتح التطبيق.
  /// Delivery Serviceability تُفحص عند Checkout فقط.
  bool get isBlocked => false;

  /// هل التوصيل المحلي نشط لهذا السياق (وليس صلاحية التصفح).
  bool get hasActiveLocalDelivery =>
      GeoAccessPolicy.hasActiveLocalDelivery(_geoContext);

  DeliveryAddress? get suggestedDefaultAddress {
    if (_browsingFallback) return null;
    if (!isSupported || _latitude == null || _longitude == null) return null;
    final gov = _governorate!;
    final labelParts = <String>[gov.name];
    if (_area.trim().isNotEmpty) {
      labelParts.add(_area.trim());
    } else if (_city.trim().isNotEmpty) {
      labelParts.add(_city.trim());
    }

    return DeliveryAddress.fromPlaceDetails(
      latitude: _latitude!,
      longitude: _longitude!,
      formattedAddress: labelParts.join(' — '),
      area: _area,
      street: '',
      governorate: gov.name,
      label: 'موقعي',
    );
  }

  Governorate get browsingCatalogGovernorate {
    if (_governorate != null && _governorate!.isAvailable) {
      return _governorate!;
    }
    for (final g in _catalog) {
      if (g.isAvailable) return g;
    }
    return EgyptGovernorates.defaultGovernorate;
  }

  Future<void> init() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _onboardingComplete = _prefs!.getBool(_keyOnboardingComplete) ?? false;
    final wasManual = _prefs!.getBool(_keyManualOverride) ?? false;
    _isManualOverride = false;
    await _prefs!.setBool(_keyManualOverride, false);
    if (wasManual) {
      // اختيار يدوي قديم لا يُعامل كموقع GPS — نعيد التحديد تلقائياً.
      await _prefs!.remove(_keyGovernorateId);
      await _prefs!.remove(_keyZoneId);
      await _prefs!.remove(_keyZoneName);
      _onboardingComplete = false;
      await _prefs!.setBool(_keyOnboardingComplete, false);
    }
    _city = _prefs!.getString(_keyCity) ?? '';
    _area = _prefs!.getString(_keyArea) ?? '';
    _unsupportedName = _prefs!.getString(_keyUnsupportedName) ?? '';
    _latitude = _prefs!.getDouble(_keyLat);
    _longitude = _prefs!.getDouble(_keyLng);
    _countryCode = _prefs!.getString(_keyCountryCode) ?? '';
    _browsingFallback = _prefs!.getBool(_keyBrowsingFallback) ?? false;
    _geoContext = _parseGeoContext(_prefs!.getString(_keyGeoContext));

    final cachedId = _prefs!.getString(_keyGovernorateId);
    if (cachedId != null) {
      _governorate = EgyptGovernorates.byId(cachedId);
    }

    final cachedZoneId = _prefs!.getString(_keyZoneId);
    final cachedZoneName = _prefs!.getString(_keyZoneName);
    if (cachedZoneId != null && cachedZoneId.isNotEmpty) {
      _matchedZone = ServiceZone(
        id: cachedZoneId,
        governorateId: cachedId ?? '',
        name: cachedZoneName ?? '',
        polygon: const [],
      );
    }

    _govSub = AppConfigService.instance.watchGovernorates().listen(
      _onCatalogUpdated,
    );

    try {
      final snap = await _governorateRepo.watchAll().first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => EgyptGovernorates.all,
      );
      _applyCatalog(snap);
    } catch (_) {
      _catalog = EgyptGovernorates.all;
    }

    _resolveCachedGovernorate();
    if (_governorate != null && (_latitude == null || _longitude == null)) {
      final center = EgyptGovernorates.centerOf(_governorate!.id);
      _latitude = center.lat;
      _longitude = center.lng;
      if (_city.isEmpty) _city = _governorate!.name;
      if (_area.isEmpty) _area = _governorate!.name;
    }
    _initialized = true;
    StartupTiming.mark('service_area_init');
    notifyListeners();
  }

  /// تحديث GPS + Geocoding في الخلفية بعد فتح التطبيق — دائماً من الموقع الحقيقي.
  Future<void> refreshLocationInBackground() async {
    if (_backgroundRefreshRunning) return;
    _backgroundRefreshRunning = true;
    notifyListeners();
    try {
      await detectFromGps(
        logAnalytics: false,
        silent: true,
        useCachedOnTimeout: true,
        preferFreshGps: true,
        gpsTimeout: const Duration(seconds: 20),
        geocodeTimeout: const Duration(seconds: 6),
      );
    } catch (_) {
      // Silent background refresh.
    } finally {
      _backgroundRefreshRunning = false;
      notifyListeners();
    }
  }

  /// إكمال سريع بآخر موقع GPS مخزّن عند انتهاء المهلة — بدون اختيار يدوي.
  Future<bool> applyCachedFallbackForTimeout() async {
    if (_browsingFallback ||
        GeoAccessPolicy.usesBrowsingFallback(_geoContext)) {
      _governorate ??= browsingCatalogGovernorate;
      _browsingFallback = true;
      _phase = ServiceAreaPhase.browsing;
      await _persist(onboardingComplete: true, governorateId: _governorate!.id);
      notifyListeners();
      unawaited(refreshLocationInBackground());
      return true;
    }
    if (_governorate != null && _governorate!.isAvailable) {
      _geoContext = UserGeoContext.egyptSupported;
      _phase = ServiceAreaPhase.supported;
      await _persist(onboardingComplete: true, governorateId: _governorate!.id);
      notifyListeners();
      unawaited(refreshLocationInBackground());
      return true;
    }
    return false;
  }

  void _onCatalogUpdated(List<Governorate> list) {
    if (list.isEmpty) return;
    _applyCatalog(list);
    _resolveCachedGovernorate();
    notifyListeners();
  }

  void _applyCatalog(List<Governorate> list) {
    _catalog = list.isEmpty ? EgyptGovernorates.all : list;
  }

  void _resolveCachedGovernorate() {
    final id = _prefs?.getString(_keyGovernorateId);
    if (id == null && !_browsingFallback) return;

    Governorate? resolved;
    if (id != null) {
      for (final g in _catalog) {
        if (g.id == id) {
          resolved = g;
          break;
        }
      }
      resolved ??= EgyptGovernorates.byId(id);
    }

    if (_browsingFallback ||
        GeoAccessPolicy.usesBrowsingFallback(_geoContext)) {
      _governorate = browsingCatalogGovernorate;
      _browsingFallback = true;
      _phase = ServiceAreaPhase.browsing;
      // لا تُسقط egyptUnsupported / outsideEgypt إلى unknown.
      if (_geoContext == UserGeoContext.egyptSupported) {
        _geoContext = UserGeoContext.unknown;
      }
      return;
    }

    if (resolved == null) return;
    _governorate = resolved;
    if (_onboardingComplete) {
      if (resolved.isAvailable &&
          _geoContext == UserGeoContext.egyptSupported) {
        _phase = ServiceAreaPhase.supported;
        _browsingFallback = false;
        _applyDefaultAddressIfNeeded();
      } else {
        // مصر غير مدعومة / خارج مصر / غير معروف → تصفح بدون حظر.
        _browsingFallback = true;
        _governorate = browsingCatalogGovernorate;
        _phase = ServiceAreaPhase.browsing;
        if (_geoContext == UserGeoContext.egyptSupported) {
          _geoContext = UserGeoContext.egyptUnsupported;
        }
      }
    }
  }

  static UserGeoContext _parseGeoContext(String? raw) {
    for (final value in UserGeoContext.values) {
      if (value.name == raw) return value;
    }
    return UserGeoContext.unknown;
  }

  Future<ServiceAreaPhase> detectFromGps({
    bool logAnalytics = true,
    Duration gpsTimeout = const Duration(seconds: 20),
    Duration geocodeTimeout = const Duration(seconds: 6),
    bool useCachedOnTimeout = false,
    bool silent = false,
    bool preferFreshGps = false,
  }) async {
    if (!silent) {
      _phase = ServiceAreaPhase.detecting;
      _errorKind = ServiceAreaErrorKind.none;
      _friendlyError = '';
      notifyListeners();
    }

    final gpsStarted = StartupTiming.elapsedMs;
    try {
      final position = await _location.getPositionForStartup(
        gpsTimeout: gpsTimeout,
        preferFresh: preferFreshGps,
      );
      StartupTiming.mark(
        'gps_acquired (+${StartupTiming.elapsedMs - gpsStarted}ms)',
      );

      PlaceDetails details;
      try {
        final geocodeStarted = StartupTiming.elapsedMs;
        details = await _maps
            .reverseGeocode(LatLng(position.latitude, position.longitude))
            .timeout(geocodeTimeout);
        StartupTiming.mark(
          'reverse_geocode (+${StartupTiming.elapsedMs - geocodeStarted}ms)',
        );
        if (details.latitude == 0 && details.longitude == 0) {
          details = PlaceDetails(
            placeId: details.placeId,
            latitude: position.latitude,
            longitude: position.longitude,
            formattedAddress: details.formattedAddress,
            area: details.area,
            street: details.street,
            city: details.city,
            governorate: details.governorate,
          );
        }
      } catch (_) {
        details = PlaceDetails(
          placeId: '',
          latitude: position.latitude,
          longitude: position.longitude,
          formattedAddress: '',
        );
      }

      return _applyDetection(details, logAnalytics: logAnalytics);
    } on TimeoutException {
      if (silent) {
        final kept = _keepSupportedIfSilent(true);
        if (kept != null) return kept;
      } else {
        final fromIp = await _applyIpFallback(logAnalytics: logAnalytics);
        if (fromIp != null) return fromIp;
      }
      if (useCachedOnTimeout) {
        final ok = await applyCachedFallbackForTimeout();
        if (ok) return _phase;
      }
      _errorKind = ServiceAreaErrorKind.unknown;
      _friendlyError = 'انتهت مهلة تحديد الموقع — حاول مرة أخرى';
      _phase = ServiceAreaPhase.error;
      notifyListeners();
      return _phase;
    } on LocationServiceException catch (e) {
      if (silent) {
        final kept = _keepSupportedIfSilent(true);
        if (kept != null) return kept;
      } else {
        final fromIp = await _applyIpFallback(logAnalytics: logAnalytics);
        if (fromIp != null) return fromIp;
      }
      if (useCachedOnTimeout &&
          (e.kind == LocationErrorKind.unknown ||
              e.kind == LocationErrorKind.serviceDisabled)) {
        final ok = await applyCachedFallbackForTimeout();
        if (ok) return _phase;
      }
      _errorKind = switch (e.kind) {
        LocationErrorKind.serviceDisabled =>
          ServiceAreaErrorKind.locationDisabled,
        LocationErrorKind.permissionDenied =>
          ServiceAreaErrorKind.permissionDenied,
        LocationErrorKind.permissionDeniedForever =>
          ServiceAreaErrorKind.permissionDeniedForever,
        LocationErrorKind.unknown => ServiceAreaErrorKind.unknown,
      };
      _friendlyError = e.message;
      _phase = ServiceAreaPhase.error;
      notifyListeners();
      return _phase;
    } on GoogleMapsApiException catch (e) {
      if (useCachedOnTimeout) {
        final ok = await applyCachedFallbackForTimeout();
        if (ok) return _phase;
      }
      final kept = _keepSupportedIfSilent(silent);
      if (kept != null) return kept;
      if (!silent) {
        final fromIp = await _applyIpFallback(logAnalytics: logAnalytics);
        if (fromIp != null) return fromIp;
      }
      _errorKind = e.code == 'network'
          ? ServiceAreaErrorKind.offline
          : ServiceAreaErrorKind.unknown;
      _friendlyError = e.message;
      _phase = ServiceAreaPhase.error;
      notifyListeners();
      return _phase;
    } catch (_) {
      final kept = _keepSupportedIfSilent(silent);
      if (kept != null) return kept;
      if (!silent) {
        final fromIp = await _applyIpFallback(logAnalytics: logAnalytics);
        if (fromIp != null) return fromIp;
      }
      _errorKind = ServiceAreaErrorKind.unknown;
      _friendlyError = 'تعذّر تحديد موقعك — حاول مرة أخرى';
      _phase = ServiceAreaPhase.error;
      notifyListeners();
      return _phase;
    }
  }

  Future<ServiceAreaPhase?> _applyIpFallback({
    required bool logAnalytics,
  }) async {
    try {
      final fix = await IpGeolocationService.instance.lookup();
      if (fix == null) return null;
      StartupTiming.mark('ip_geolocation');
      return _applyDetection(
        PlaceDetails(
          placeId: '',
          latitude: fix.latitude,
          longitude: fix.longitude,
          formattedAddress: [
            fix.city,
            fix.region,
          ].where((s) => s.isNotEmpty).join(' — '),
          city: fix.city,
          area: fix.city,
          governorate: fix.region.isNotEmpty ? fix.region : fix.city,
          countryCode: fix.countryCode,
        ),
        logAnalytics: logAnalytics,
      );
    } catch (_) {
      return null;
    }
  }

  /// تحديث خلفي فاشل لا يطرد العميل من الكتالوج الحالي.
  ServiceAreaPhase? _keepSupportedIfSilent(bool silent) {
    if (!silent) return null;
    if (_phase == ServiceAreaPhase.browsing || _browsingFallback) {
      _phase = ServiceAreaPhase.browsing;
      return _phase;
    }
    if (_governorate == null || !_governorate!.isAvailable) return null;
    if (_geoContext == UserGeoContext.egyptSupported) {
      _phase = ServiceAreaPhase.supported;
      return _phase;
    }
    return null;
  }

  Future<ServiceAreaPhase> _applyDetection(
    PlaceDetails details, {
    required bool logAnalytics,
  }) async {
    _latitude = details.latitude;
    _longitude = details.longitude;
    _city = details.city;
    _area = details.area.isNotEmpty ? details.area : details.city;
    _unsupportedName = details.governorate.isNotEmpty
        ? details.governorate
        : (details.city.isNotEmpty ? details.city : 'منطقتك');
    _countryCode = GeoAccessPolicy.normalizeCountryCode(details.countryCode);

    final matched =
        ServiceAreaGovernorateMatcher.match(
          details.governorate.isNotEmpty ? details.governorate : details.city,
          _catalog,
        ) ??
        ServiceAreaGovernorateMatcher.matchByCoordinates(
          _latitude!,
          _longitude!,
          _catalog,
        );

    final hasCoords = !(_latitude == 0 && _longitude == 0);
    final inEgyptBounds =
        hasCoords &&
        GeoAccessPolicy.isInsideEgyptBounds(_latitude!, _longitude!);

    _geoContext = GeoAccessPolicy.resolve(
      GeoResolutionInput(
        countryCode: _countryCode,
        hasCoordinates: hasCoords,
        coordinatesInEgyptBounds: inEgyptBounds,
        matchedEgyptianGovernorate: matched != null,
        matchedGovernorateAvailable: matched?.isAvailable ?? false,
      ),
    );

    _isManualOverride = false;

    switch (_geoContext) {
      case UserGeoContext.egyptSupported:
        _governorate = matched;
        _browsingFallback = false;
        if (matched != null) {
          if (_city.trim().isEmpty) _city = matched.name;
          if (_area.trim().isEmpty) _area = matched.name;
        }
        _phase = ServiceAreaPhase.supported;
        await _persist(
          onboardingComplete: true,
          governorateId: matched!.id,
          manualOverride: false,
        );
        _applyDefaultAddressIfNeeded();
        await _detectZone(LatLng(_latitude!, _longitude!), matched.id);
        if (logAnalytics) {
          unawaited(
            _analytics.log(
              type: ServiceAreaEventType.supported,
              governorate: matched.name,
              governorateId: matched.id,
              supported: true,
              city: _city,
              area: _area,
              countryCode: _countryCode,
              geoContext: _geoContext.name,
            ),
          );
        }
        break;

      case UserGeoContext.egyptUnsupported:
      case UserGeoContext.outsideEgypt:
      case UserGeoContext.unknown:
        final displayName = matched?.name ?? _unsupportedName;
        if (_geoContext == UserGeoContext.egyptUnsupported) {
          _unsupportedName = displayName;
        }
        await _enterBrowsingFallback(
          context: _geoContext,
          logAnalytics: logAnalytics,
          preserveUnsupportedName:
              _geoContext == UserGeoContext.egyptUnsupported
              ? displayName
              : null,
        );
        break;
    }

    notifyListeners();
    return _phase;
  }

  /// تصفح الكتالوج بمحافظة افتراضية مدعومة — بدون حظر وبدون عنوان توصيل تلقائي.
  Future<void> _enterBrowsingFallback({
    required UserGeoContext context,
    required bool logAnalytics,
    String? preserveUnsupportedName,
  }) async {
    _geoContext = context;
    _browsingFallback = true;
    _matchedZone = null;
    _governorate = browsingCatalogGovernorate;
    _phase = ServiceAreaPhase.browsing;
    await _persist(
      onboardingComplete: true,
      governorateId: _governorate!.id,
      manualOverride: false,
      unsupportedName: preserveUnsupportedName ?? '',
    );
    await _prefs?.remove(_keyZoneId);
    await _prefs?.remove(_keyZoneName);
    if (logAnalytics) {
      final type = switch (context) {
        UserGeoContext.egyptUnsupported => ServiceAreaEventType.unsupported,
        UserGeoContext.outsideEgypt => ServiceAreaEventType.outsideEgypt,
        UserGeoContext.unknown => ServiceAreaEventType.unknownGeo,
        UserGeoContext.egyptSupported => ServiceAreaEventType.supported,
      };
      unawaited(
        _analytics.log(
          type: type,
          governorate: preserveUnsupportedName?.isNotEmpty == true
              ? preserveUnsupportedName!
              : _governorate!.name,
          governorateId: _governorate!.id,
          supported: false,
          city: _city,
          area: _area,
          countryCode: _countryCode,
          geoContext: _geoContext.name,
        ),
      );
    }
  }

  /// دخول تصفح عند رفض الموقع / الفشل — بدون Blocking دائم.
  Future<ServiceAreaPhase> completeAsBrowsingFallback({
    UserGeoContext context = UserGeoContext.unknown,
  }) async {
    _errorKind = ServiceAreaErrorKind.none;
    _friendlyError = '';
    await _enterBrowsingFallback(context: context, logAnalytics: true);
    notifyListeners();
    return _phase;
  }

  Future<void> completeOnboardingWithManual(Governorate selected) async {
    if (!selected.isAvailable) return;
    _governorate = selected;
    _isManualOverride = true;
    _geoContext = UserGeoContext.egyptSupported;
    _browsingFallback = false;
    _countryCode = GeoAccessPolicy.egyptCountryCode;
    _phase = ServiceAreaPhase.supported;
    _unsupportedName = '';
    final center = EgyptGovernorates.centerOfGovernorate(selected);
    _latitude = center.lat;
    _longitude = center.lng;
    _city = selected.name;
    _area = selected.name;
    await _persist(
      onboardingComplete: true,
      governorateId: selected.id,
      manualOverride: true,
    );
    unawaited(
      _analytics.log(
        type: ServiceAreaEventType.manualOverride,
        governorate: selected.name,
        governorateId: selected.id,
        supported: true,
        manual: true,
        countryCode: _countryCode,
        geoContext: _geoContext.name,
      ),
    );
    notifyListeners();
  }

  Future<void> setGovernorateManual(Governorate selected) async {
    if (!selected.isAvailable) return;
    final prev = _governorate?.id;
    _governorate = selected;
    _isManualOverride = true;
    _geoContext = UserGeoContext.egyptSupported;
    _browsingFallback = false;
    _countryCode = GeoAccessPolicy.egyptCountryCode;
    _phase = ServiceAreaPhase.supported;
    _unsupportedName = '';
    await _persist(
      onboardingComplete: true,
      governorateId: selected.id,
      manualOverride: true,
    );
    if (prev != selected.id) {
      unawaited(
        _analytics.log(
          type: ServiceAreaEventType.manualOverride,
          governorate: selected.name,
          governorateId: selected.id,
          supported: true,
          manual: true,
          countryCode: _countryCode,
          geoContext: _geoContext.name,
        ),
      );
    }
    notifyListeners();
  }

  Future<ServiceAreaPhase> retryDetection() async {
    unawaited(
      _analytics.log(
        type: ServiceAreaEventType.retryDetection,
        governorate: _unsupportedName,
        supported: false,
      ),
    );
    return detectFromGps(
      useCachedOnTimeout: _governorate != null,
      preferFreshGps: false,
      gpsTimeout: const Duration(seconds: 20),
    );
  }

  void _applyDefaultAddressIfNeeded() {
    final address = suggestedDefaultAddress;
    if (address == null) return;
    if (DeliveryAddressSession.instance.hasValidAddress) return;
    DeliveryAddressSession.instance.setAddress(address);
  }

  Future<void> _detectZone(LatLng position, String governorateId) async {
    try {
      _activeZones = await _zoneRepo.fetchAllActive();
      final govZones = _activeZones.where(
        (z) => z.governorateId == governorateId,
      );
      _matchedZone = null;
      for (final zone in govZones) {
        if (zone.containsPoint(position)) {
          _matchedZone = zone;
          break;
        }
      }
      if (_matchedZone != null) {
        await _prefs?.setString(_keyZoneId, _matchedZone!.id);
        await _prefs?.setString(_keyZoneName, _matchedZone!.name);
      } else {
        await _prefs?.remove(_keyZoneId);
        await _prefs?.remove(_keyZoneName);
      }
    } catch (_) {
      // Zone detection is best-effort; don't block onboarding
    }
  }

  Future<void> _persist({
    required bool onboardingComplete,
    String? governorateId,
    bool? manualOverride,
    String? unsupportedName,
  }) async {
    _onboardingComplete = onboardingComplete;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    await prefs.setBool(_keyOnboardingComplete, onboardingComplete);
    if (governorateId != null) {
      await prefs.setString(_keyGovernorateId, governorateId);
    }
    if (manualOverride != null) {
      _isManualOverride = manualOverride;
      await prefs.setBool(_keyManualOverride, manualOverride);
    }
    if (_city.isNotEmpty) await prefs.setString(_keyCity, _city);
    if (_area.isNotEmpty) await prefs.setString(_keyArea, _area);
    if (_latitude != null) await prefs.setDouble(_keyLat, _latitude!);
    if (_longitude != null) await prefs.setDouble(_keyLng, _longitude!);
    if (unsupportedName != null) {
      _unsupportedName = unsupportedName;
      if (unsupportedName.isEmpty) {
        await prefs.remove(_keyUnsupportedName);
      } else {
        await prefs.setString(_keyUnsupportedName, unsupportedName);
      }
    }
    await prefs.setString(_keyGeoContext, _geoContext.name);
    await prefs.setString(_keyCountryCode, _countryCode);
    await prefs.setBool(_keyBrowsingFallback, _browsingFallback);
  }

  @override
  void dispose() {
    unawaited(_govSub?.cancel());
    super.dispose();
  }
}
