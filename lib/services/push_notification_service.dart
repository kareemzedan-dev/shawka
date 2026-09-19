import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/navigation/startup_navigation.dart';
import 'package:matlobgo/models/push_deep_link.dart';
import 'package:matlobgo/repositories/user_repository.dart';
import 'package:matlobgo/services/notification_service.dart';
import 'package:matlobgo/services/push_deep_link_service.dart';

/// يحفظ fcmToken في Firestore ويربطه بحالة تسجيل الدخول + Deep Links.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepo = UserRepository();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenSub;
  String? _boundUid;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.setAutoInitEnabled(true);
    await _requestPermission();

    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    _tokenSub = _messaging.onTokenRefresh.listen(_persistToken);

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? AppBranding.shortName;
      final body = message.notification?.body ?? '';
      final data = message.data;
      // السيرفر يكتب الـ inbox مسبقاً لحملات/حالات الطلب — نتجنب التكرار.
      final serverWroteInbox = data.containsKey('campaignId') ||
          data.containsKey('orderId') ||
          data['inboxWritten'] == '1' ||
          data['inboxWritten'] == 'true';
      if (!serverWroteInbox && (title.isNotEmpty || body.isNotEmpty)) {
        unawaited(
          NotificationService.instance.recordIncoming(
            title: title,
            body: body,
            type: data['type'] as String?,
            deepLink: data['deepLink'] as String?,
            deepLinkId: data['deepLinkId'] as String?,
          ),
        );
      }
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        PushForegroundBanner.show(ctx, message);
      }
      if (kDebugMode) {
        debugPrint('FCM foreground: $title');
      }
    });

    unawaited(PushDeepLinkService.instance.wireMessagingHandlers());

    final user = _auth.currentUser;
    if (user != null) {
      _boundUid = user.uid;
      await _persistToken(await _messaging.getToken());
      await _userRepo.touchLastActive(user.uid);
    }
  }

  Future<void> touchActive() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _userRepo.touchLastActive(uid);
  }

  Future<String?> currentToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    final previousUid = _boundUid;
    _boundUid = user?.uid;

    if (previousUid != null && previousUid != user?.uid) {
      await _userRepo.clearFcmToken(previousUid);
    }

    if (user == null) return;

    await _persistToken(await _messaging.getToken());
    await _userRepo.touchLastActive(user.uid);
  }

  Future<void> _persistToken(String? token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token == null || token.length < 10) return;
    await _userRepo.updateFcmToken(uid, token);
  }

  void dispose() {
    _authSub?.cancel();
    _tokenSub?.cancel();
  }
}

/// Banner داخل التطبيق عند وصول إشعار foreground (اختياري).
class PushForegroundBanner {
  static void show(BuildContext context, RemoteMessage message) {
    final link = PushDeepLink.fromFcmData(message.data);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.notification?.title ?? message.notification?.body ?? 'إشعار',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'فتح',
          onPressed: () => PushDeepLinkService.instance.handleData(message.data),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
      ),
    );
    if (kDebugMode) debugPrint('Push deep link: ${link.route.name}');
  }
}
