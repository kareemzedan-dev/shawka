import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/app_notification.dart';
import 'package:matlobgo/repositories/customer_notification_repository.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _repo = CustomerNotificationRepository();
  StreamSubscription<List<AppNotification>>? _sub;
  List<AppNotification> _notifications = [];
  String? _uid;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _sub?.cancel();
    _uid = uid;
    _notifications = [];
    if (uid == null || uid.isEmpty) {
      notifyListeners();
      return;
    }
    _sub = _repo.watch(uid).listen((list) {
      _notifications = list;
      notifyListeners();
    });
  }

  void syncAuth() {
    bindUser(FirebaseAuth.instance.currentUser?.uid);
  }

  Future<void> markAsRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.markRead(uid, id);
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.markAllRead(uid);
  }

  Future<void> recordIncoming({
    required String title,
    required String body,
    String? type,
    String? deepLink,
    String? deepLinkId,
  }) async {
    final uid = _uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _repo.persist(
      uid: uid,
      title: title,
      body: body,
      type: type,
      deepLink: deepLink,
      deepLinkId: deepLinkId,
    );
  }
}
