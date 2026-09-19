import 'package:flutter/material.dart';
import 'package:matlobgo/models/push_deep_link.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = 'general',
    this.deepLink = '',
    this.deepLinkId = '',
    this.icon = Icons.notifications_rounded,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// order_status | campaign | promo | system | general
  final String type;
  final String deepLink;
  final String deepLinkId;
  final IconData icon;

  bool get hasDeepLink =>
      deepLink.trim().isNotEmpty || deepLinkId.trim().isNotEmpty;

  PushDeepLink toPushDeepLink() {
    if (deepLink.trim().isNotEmpty) {
      return PushDeepLink(
        route: PushDeepLinkRouteX.fromFirestore(deepLink),
        id: deepLinkId,
      );
    }
    if (type == 'order_status' && deepLinkId.isNotEmpty) {
      return PushDeepLink(route: PushDeepLinkRoute.order, id: deepLinkId);
    }
    if (type == 'campaign' || type == 'promo') {
      return const PushDeepLink(route: PushDeepLinkRoute.promotions);
    }
    return const PushDeepLink(route: PushDeepLinkRoute.none);
  }

  AppNotification copyWith({
    bool? isRead,
    String? type,
    String? deepLink,
    String? deepLinkId,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      deepLink: deepLink ?? this.deepLink,
      deepLinkId: deepLinkId ?? this.deepLinkId,
      icon: icon,
    );
  }
}
