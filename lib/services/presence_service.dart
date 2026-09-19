import 'dart:async';

import 'package:matlobgo/repositories/user_repository.dart';
import 'package:matlobgo/services/auth_service.dart';

/// نبض حضور — يحدّث lastActiveAt دورياً أثناء استخدام التطبيق.
class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  static const _heartbeatInterval = Duration(minutes: 2);
  static const onlineThreshold = Duration(minutes: 5);

  final _userRepo = UserRepository();
  final _auth = AuthService();

  Timer? _timer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    unawaited(_pulse());
    _timer?.cancel();
    _timer = Timer.periodic(_heartbeatInterval, (_) => _pulse());
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> pulse() => _pulse();

  Future<void> _pulse() async {
    final user = await _auth.getCurrentAppUser();
    if (user == null || user.isGuest) return;
    await _userRepo.touchLastActive(user.uid);
  }

  static bool isOnline(DateTime? lastActiveAt, [DateTime? now]) {
    if (lastActiveAt == null) return false;
    final ref = now ?? DateTime.now();
    return ref.difference(lastActiveAt) <= onlineThreshold;
  }

  void dispose() => stop();
}
