import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/ui_polish_tokens.dart';
import 'package:matlobgo/models/app_notification.dart';

enum NotificationUiCategory { all, orders, offers, system }

extension NotificationUiCategoryX on NotificationUiCategory {
  String get label => switch (this) {
        NotificationUiCategory.all => 'الكل',
        NotificationUiCategory.orders => 'الطلبات',
        NotificationUiCategory.offers => 'العروض',
        NotificationUiCategory.system => 'النظام',
      };
}

NotificationUiCategory categorizeNotification(AppNotification n) {
  final type = n.type.toLowerCase();
  if (type.contains('order') ||
      n.deepLink == 'order' ||
      n.deepLink == 'orders') {
    return NotificationUiCategory.orders;
  }
  if (type.contains('campaign') ||
      type.contains('promo') ||
      type.contains('offer') ||
      n.deepLink == 'promotions' ||
      n.deepLink == 'store') {
    return NotificationUiCategory.offers;
  }

  final text = '${n.title} ${n.body}'.toLowerCase();
  if (text.contains('طلب') ||
      text.contains('توصيل') ||
      text.contains('order') ||
      text.contains('مندوب') ||
      text.contains('تسليم')) {
    return NotificationUiCategory.orders;
  }
  if (text.contains('عرض') ||
      text.contains('خصم') ||
      text.contains('كوبون') ||
      text.contains('promo') ||
      text.contains('تخفيض')) {
    return NotificationUiCategory.offers;
  }
  return NotificationUiCategory.system;
}

class NotificationVisual {
  const NotificationVisual({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

NotificationVisual visualForCategory(NotificationUiCategory category) {
  return switch (category) {
    NotificationUiCategory.orders => NotificationVisual(
        icon: Icons.delivery_dining_rounded,
        color: UiPolishTokens.success,
        background: UiPolishTokens.success.withValues(alpha: 0.12),
      ),
    NotificationUiCategory.offers => NotificationVisual(
        icon: Icons.local_offer_rounded,
        color: AppColors.primary,
        background: AppColors.primary.withValues(alpha: 0.12),
      ),
    NotificationUiCategory.system => NotificationVisual(
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF3B82F6),
        background: const Color(0xFF3B82F6).withValues(alpha: 0.12),
      ),
    NotificationUiCategory.all => NotificationVisual(
        icon: Icons.notifications_rounded,
        color: AppColors.primary,
        background: AppColors.primary.withValues(alpha: 0.12),
      ),
  };
}

/// تجميع حسب اليوم للعرض البريميوم.
String notificationDayGroupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'اليوم';
  if (diff == 1) return 'أمس';
  if (diff < 7) return 'هذا الأسبوع';
  return 'أقدم';
}
