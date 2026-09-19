import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// صلاحيات GPS وقراءة الموقع — بدون تسجيل إحداثيات في الـ logs.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  /// يطلب الصلاحية ويعيد true إذا أصبحت متاحة للاستخدام.
  Future<bool> ensurePermission({bool requestBackground = false}) async {
    if (!await isServiceEnabled()) {
      throw const LocationServiceException(
        LocationErrorKind.serviceDisabled,
        'فعّل خدمة الموقع من إعدادات الجهاز',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        LocationErrorKind.permissionDenied,
        'لم يتم منح صلاحية الموقع',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        LocationErrorKind.permissionDeniedForever,
        'صلاحية الموقع مرفوضة — افتح الإعدادات للسماح',
      );
    }

    if (requestBackground &&
        permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        if (kDebugMode) {
          debugPrint('LocationService: background permission not granted');
        }
      }
    }

    return true;
  }

  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 20),
  }) async {
    await ensurePermission();
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(accuracy: accuracy),
      ).timeout(timeLimit);
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// أول إحداثيات متاحة: آخر موقع معروف بالتوازي مع Fused و LocationManager.
  Future<Position> getPositionForStartup({
    Duration gpsTimeout = const Duration(seconds: 12),
    Duration lastKnownMaxAge = const Duration(days: 14),
    bool preferFresh = false,
  }) async {
    await ensurePermission();

    final lastKnown = await _safeLastKnown();
    if (!preferFresh &&
        lastKnown != null &&
        _isFreshEnough(lastKnown, lastKnownMaxAge)) {
      return lastKnown;
    }

    try {
      return await _raceFixes(
        budget: gpsTimeout,
        seed: lastKnown,
      );
    } catch (e) {
      if (lastKnown != null) return lastKnown;
      throw _mapError(e);
    }
  }

  Future<Position> getCurrentPositionFast({
    Duration timeout = const Duration(seconds: 12),
    Duration lastKnownMaxAge = const Duration(days: 14),
  }) {
    return getPositionForStartup(
      gpsTimeout: timeout,
      lastKnownMaxAge: lastKnownMaxAge,
      preferFresh: false,
    );
  }

  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    int distanceFilterMeters = 25,
    Duration interval = const Duration(seconds: 30),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _settings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
        interval: interval,
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<Position> _raceFixes({
    required Duration budget,
    Position? seed,
  }) async {
    final completer = Completer<Position>();
    StreamSubscription<Position>? streamSub;

    void offer(Position position) {
      if (!completer.isCompleted) completer.complete(position);
    }

    if (seed != null) {
      // إن تأخر المزودون، ندخل بآخر موقع معروف بدل المهلة.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 2), () => offer(seed)),
      );
    }

    unawaited(() async {
      try {
        offer(
          await Geolocator.getCurrentPosition(
            locationSettings: _settings(accuracy: LocationAccuracy.medium),
          ),
        );
      } catch (_) {}
    }());
    unawaited(() async {
      try {
        offer(
          await Geolocator.getCurrentPosition(
            locationSettings: _settings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
            ),
          ),
        );
      } catch (_) {}
    }());

    try {
      streamSub = Geolocator.getPositionStream(
        locationSettings: _settings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 0,
          interval: const Duration(milliseconds: 500),
        ),
      ).listen(offer, onError: (_) {});
    } catch (_) {}

    try {
      return await completer.future.timeout(budget);
    } finally {
      unawaited(streamSub?.cancel());
    }
  }

  Future<Position?> _safeLastKnown() async {
    try {
      final fused = await Geolocator.getLastKnownPosition();
      if (fused != null) return fused;
    } catch (_) {}
    try {
      return await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isFreshEnough(Position position, Duration maxAge) {
    return DateTime.now().difference(position.timestamp) <= maxAge;
  }

  LocationSettings _settings({
    required LocationAccuracy accuracy,
    int distanceFilter = 0,
    Duration? interval,
    bool forceLocationManager = false,
  }) {
    if (kIsWeb) {
      return LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          forceLocationManager: forceLocationManager,
          intervalDuration: interval ?? const Duration(seconds: 1),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: accuracy,
          activityType: ActivityType.other,
          distanceFilter: distanceFilter,
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        );
    }
  }

  LocationServiceException _mapError(Object e) {
    if (e is LocationServiceException) return e;
    if (e is TimeoutException) {
      return const LocationServiceException(
        LocationErrorKind.unknown,
        'انتهت مهلة تحديد الموقع — حاول مرة أخرى',
      );
    }
    if (e is LocationServiceDisabledException) {
      return const LocationServiceException(
        LocationErrorKind.serviceDisabled,
        'خدمة الموقع غير مفعّلة',
      );
    }
    if (e is PermissionDeniedException) {
      return const LocationServiceException(
        LocationErrorKind.permissionDenied,
        'صلاحية الموقع مرفوضة',
      );
    }
    return const LocationServiceException(
      LocationErrorKind.unknown,
      'تعذّر تحديد موقعك — حاول مرة أخرى',
    );
  }
}

enum LocationErrorKind {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.kind, this.message);

  final LocationErrorKind kind;
  final String message;

  @override
  String toString() => message;
}
