import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/push_deep_link.dart';

typedef PushDeepLinkHandler = Future<void> Function(PushDeepLink link);

/// يوجّه المستخدم عند النقر على إشعار Push (foreground / background / terminated).
class PushDeepLinkService {
  PushDeepLinkService._();

  static final PushDeepLinkService instance = PushDeepLinkService._();

  PushDeepLinkHandler? _handler;
  bool _wired = false;

  void bindHandler(PushDeepLinkHandler handler) {
    _handler = handler;
  }

  Future<void> wireMessagingHandlers() async {
    if (_wired) return;
    _wired = true;

    FirebaseMessaging.onMessageOpenedApp.listen(_onMessage);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      unawaited(_onMessage(initial));
    }
  }

  Future<void> _onMessage(RemoteMessage message) async {
    final data = message.data;
    if (data.isEmpty) return;
    final link = PushDeepLink.fromFcmData(data);
    if (link.route == PushDeepLinkRoute.none && link.id.isEmpty) return;
    if (_handler == null) {
      if (kDebugMode) {
        debugPrint('PushDeepLink pending — no handler: ${link.route.name}');
      }
      return;
    }
    await _handler!(link);
  }

  /// للاختبار من foreground notification tap (optional).
  Future<void> handleData(Map<String, dynamic> data) async {
    await _onMessage(RemoteMessage(data: data));
  }
}
