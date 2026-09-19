import 'dart:math';

import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/services/analytics_remote_service.dart';

/// تتبع رحلة المستخدم — جلسات، شاشات، وسلة — عبر Cloud Function.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const _idleThreshold = Duration(minutes: 30);
  static const _screenDedupeWindow = Duration(seconds: 2);

  final _remote = AnalyticsRemoteService();
  final _random = Random();

  String? _userId;
  String _userName = '';
  String? _sessionId;
  DateTime? _sessionStartedAt;
  int _sessionEventCount = 0;
  DateTime? _lastSessionActivity;
  String? _lastScreenView;
  DateTime? _lastScreenViewAt;

  void bindUser({required String? userId, required String userName}) {
    _userId = userId;
    _userName = userName;
    if (userId == null || userId.isEmpty) {
      _clearSession();
    }
  }

  String? get sessionId => _sessionId;

  int get sessionDurationSeconds {
    if (_sessionStartedAt == null) return 0;
    return DateTime.now().difference(_sessionStartedAt!).inSeconds;
  }

  Future<void> appOpen() async {
    await _ensureSession();
    await track(
      type: AnalyticsEventType.appOpen,
      screen: 'app',
      label: 'فتح التطبيق',
    );
  }

  Future<void> endSession({String reason = 'background'}) async {
    if (_userId == null || _sessionId == null || _sessionStartedAt == null) {
      return;
    }
    final duration = DateTime.now().difference(_sessionStartedAt!).inSeconds;
    if (duration < 3 && _sessionEventCount <= 1) {
      _clearSession();
      return;
    }
    await track(
      type: AnalyticsEventType.sessionEnd,
      screen: 'app',
      label: 'انتهاء الجلسة (${_formatDuration(duration)})',
      metadata: {
        'sessionId': _sessionId!,
        'durationSeconds': duration,
        'eventCount': _sessionEventCount,
        'reason': reason,
      },
    );
    _clearSession();
  }

  Future<void> screenView({
    required String screen,
    String? label,
  }) async {
    final now = DateTime.now();
    if (_lastScreenView == screen &&
        _lastScreenViewAt != null &&
        now.difference(_lastScreenViewAt!) < _screenDedupeWindow) {
      return;
    }
    _lastScreenView = screen;
    _lastScreenViewAt = now;
    await track(
      type: AnalyticsEventType.screenView,
      screen: screen,
      label: label ?? screen,
    );
  }

  Future<void> removeFromCart({
    required String screen,
    required String productName,
    String storeId = '',
    String storeName = '',
    String productId = '',
    int quantity = 1,
  }) {
    return track(
      type: AnalyticsEventType.removeFromCart,
      screen: screen,
      label: 'حذف $productName',
      storeId: storeId,
      storeName: storeName,
      productId: productId,
      productName: productName,
      metadata: {'quantity': quantity},
    );
  }

  Future<void> track({
    required AnalyticsEventType type,
    required String screen,
    required String label,
    String storeId = '',
    String storeName = '',
    String productId = '',
    String productName = '',
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null || _userId!.isEmpty) return;
    await _ensureSession();
    _sessionEventCount++;
    _lastSessionActivity = DateTime.now();

    final merged = <String, dynamic>{
      ...?metadata,
      'sessionId': ?_sessionId,
    };

    return _remote.track(
      AnalyticsEvent(
        id: '',
        userId: _userId!,
        userName: _userName,
        type: type,
        screen: screen,
        label: label,
        createdAt: DateTime.now(),
        storeId: storeId,
        storeName: storeName,
        productId: productId,
        productName: productName,
        metadata: merged,
      ),
    );
  }

  Future<void> _ensureSession() async {
    if (_userId == null || _userId!.isEmpty) return;

    final now = DateTime.now();
    final idle = _lastSessionActivity == null
        ? null
        : now.difference(_lastSessionActivity!);

    if (_sessionId != null &&
        idle != null &&
        idle < _idleThreshold) {
      return;
    }

    if (_sessionId != null) {
      await endSession(reason: 'idle_timeout');
    }

    _sessionId =
        '${now.millisecondsSinceEpoch}_${_random.nextInt(999999).toString().padLeft(6, '0')}';
    _sessionStartedAt = now;
    _sessionEventCount = 0;
    _lastSessionActivity = now;

    await _remote.track(
      AnalyticsEvent(
        id: '',
        userId: _userId!,
        userName: _userName,
        type: AnalyticsEventType.sessionStart,
        screen: 'app',
        label: 'بداية جلسة جديدة',
        createdAt: now,
        metadata: {'sessionId': _sessionId!},
      ),
    );
    _sessionEventCount = 1;
  }

  void _clearSession() {
    _sessionId = null;
    _sessionStartedAt = null;
    _sessionEventCount = 0;
    _lastSessionActivity = null;
    _lastScreenView = null;
    _lastScreenViewAt = null;
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds ث';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m < 60) return s == 0 ? '$m د' : '$m د $s ث';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm == 0 ? '$h س' : '$h س $rm د';
  }
}
