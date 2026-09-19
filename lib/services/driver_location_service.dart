import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/repositories/user_repository.dart';
import 'package:matlobgo/services/auth_service.dart';

/// يرسل موقع المندوب إلى Firestore بشكل دوري.
class DriverLocationService {
  DriverLocationService._();

  static final DriverLocationService instance = DriverLocationService._();

  final _userRepo = UserRepository();
  final _auth = AuthService();

  Timer? _timer;
  bool _running = false;

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final user = await _auth.getCurrentAppUser();
    if (user == null || !user.isDelivery) return;
    await _userRepo.updateDriverLocation(
      uid: user.uid,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void startPeriodicUpdates(
    Future<({double lat, double lng})?> Function() readLocation, {
    Duration interval = const Duration(seconds: 30),
  }) {
    if (_running) return;
    _running = true;
    unawaited(_tick(readLocation));
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick(readLocation));
  }

  Future<void> _tick(
    Future<({double lat, double lng})?> Function() readLocation,
  ) async {
    try {
      final pos = await readLocation();
      if (pos == null) return;
      await updateLocation(latitude: pos.lat, longitude: pos.lng);
    } catch (e) {
      if (kDebugMode) debugPrint('DriverLocationService: $e');
    }
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }
}
