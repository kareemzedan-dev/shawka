import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/bottom_nav_config.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/notification_service.dart';
import 'package:matlobgo/services/order_service.dart';

/// أنواع الشارات المدعومة — قابلة للتوسع دون تغيير الـ UI.
enum AppBadgeKind { cart, orders, notifications }

enum AppBadgeStyle { count, dot }

/// مزوّد شارات ديناميكي موحّد للـ Bottom Navigation.
class AppBadgeProvider extends ChangeNotifier {
  AppBadgeProvider._();
  static final AppBadgeProvider instance = AppBadgeProvider._();

  CartService? _cart;
  OrderService? _orders;
  NotificationService? _notifications;
  AppConfigService? _config;
  bool _bound = false;

  int _cartCount = 0;
  int _ordersCount = 0;
  int _notificationsCount = 0;
  bool _badgesEnabled = true;
  String _badgeStyle = 'count';
  bool _cartBadgeEnabled = true;
  bool _ordersBadgeEnabled = false;

  int get cartCount => _cartCount;
  int get ordersCount => _ordersCount;
  int get notificationsCount => _notificationsCount;

  void bind({
    CartService? cart,
    OrderService? orders,
    NotificationService? notifications,
    AppConfigService? config,
  }) {
    if (_bound) {
      _cart?.removeListener(_sync);
      _orders?.removeListener(_sync);
      _notifications?.removeListener(_sync);
      _config?.removeListener(_sync);
    }
    _cart = cart ?? CartService.instance;
    _orders = orders ?? OrderService.instance;
    _notifications = notifications ?? NotificationService.instance;
    _config = config ?? AppConfigService.instance;
    _cart!.addListener(_sync);
    _orders!.addListener(_sync);
    _notifications!.addListener(_sync);
    _config!.addListener(_sync);
    _bound = true;
    _sync();
  }

  void unbind() {
    if (!_bound) return;
    _cart?.removeListener(_sync);
    _orders?.removeListener(_sync);
    _notifications?.removeListener(_sync);
    _config?.removeListener(_sync);
    _bound = false;
  }

  void _sync() {
    final nav = _config?.settings.bottomNav ?? const BottomNavConfig();
    final nextCart = _cart?.itemCount ?? 0;
    final nextOrders = _orders?.activeOrders.length ?? 0;
    final nextNotifications = _notifications?.unreadCount ?? 0;
    final nextCartBadge = nav.tabs.any((t) => t.id == 'cart' && t.showBadge);
    final nextOrdersBadge = nav.tabs.any(
      (t) => t.id == 'orders' && t.showBadge,
    );
    final changed =
        nextCart != _cartCount ||
        nextOrders != _ordersCount ||
        nextNotifications != _notificationsCount ||
        nav.badgeEnabled != _badgesEnabled ||
        nav.badgeStyle != _badgeStyle ||
        nextCartBadge != _cartBadgeEnabled ||
        nextOrdersBadge != _ordersBadgeEnabled;
    _cartCount = nextCart;
    _ordersCount = nextOrders;
    _notificationsCount = nextNotifications;
    _badgesEnabled = nav.badgeEnabled;
    _badgeStyle = nav.badgeStyle;
    _cartBadgeEnabled = nextCartBadge;
    _ordersBadgeEnabled = nextOrdersBadge;
    if (changed) notifyListeners();
  }

  AppBadgeStyle get style =>
      _badgeStyle == 'dot' ? AppBadgeStyle.dot : AppBadgeStyle.count;

  bool get badgesEnabled => _badgesEnabled;

  bool isSlotEnabled(AppBadgeKind kind) {
    if (!badgesEnabled) return false;
    return switch (kind) {
      AppBadgeKind.cart => _cartBadgeEnabled,
      AppBadgeKind.orders => _ordersBadgeEnabled,
      AppBadgeKind.notifications => false,
    };
  }

  int countFor(AppBadgeKind kind) => switch (kind) {
    AppBadgeKind.cart => _cartCount,
    AppBadgeKind.orders => _ordersCount,
    AppBadgeKind.notifications => _notificationsCount,
  };

  bool shouldShow(AppBadgeKind kind) =>
      isSlotEnabled(kind) && countFor(kind) > 0;

  String? labelFor(AppBadgeKind kind) {
    if (!shouldShow(kind)) return null;
    if (style == AppBadgeStyle.dot) return '';
    final count = countFor(kind);
    return count > 99 ? '99+' : '$count';
  }
}
