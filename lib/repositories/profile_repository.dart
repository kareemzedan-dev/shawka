import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/favorites_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/services/theme_service.dart';

/// مستودع حسابي — واجهة مستقرة للـ ProfileController.
class ProfileRepository {
  ProfileRepository({
    OrderService? orderService,
    FavoritesService? favoritesService,
    ThemeService? themeService,
    AppConfigService? configService,
    AuthService? authService,
  })  : _ordersOverride = orderService,
        _favoritesOverride = favoritesService,
        _themeOverride = themeService,
        _configOverride = configService,
        _authOverride = authService;

  final OrderService? _ordersOverride;
  final FavoritesService? _favoritesOverride;
  final ThemeService? _themeOverride;
  final AppConfigService? _configOverride;
  final AuthService? _authOverride;

  OrderService get _orders => _ordersOverride ?? OrderService.instance;
  FavoritesService get _favorites =>
      _favoritesOverride ?? FavoritesService.instance;
  ThemeService get _theme => _themeOverride ?? ThemeService.instance;
  AppConfigService get _config =>
      _configOverride ?? AppConfigService.instance;
  AuthService get _auth => _authOverride ?? AuthService();

  Listenable get dataListenable => Listenable.merge([
        _orders,
        _favorites,
        _theme,
        _config,
      ]);

  List<Order> get orders => _orders.orders;

  Order? get lastOrder => orders.isEmpty ? null : orders.first;

  int get ordersCount => orders.length;

  int get favoritesCount => _favorites.totalCount;

  /// عناوين فريدة من الطلبات + محافظة المستخدم كحد أدنى.
  int addressCount({String? governorate}) {
    final unique = <String>{};
    for (final order in orders) {
      final address = order.address?.trim();
      if (address != null && address.isNotEmpty) unique.add(address);
    }
    if (unique.isNotEmpty) return unique.length;
    if (governorate != null && governorate.trim().isNotEmpty) return 1;
    return 0;
  }

  /// أكواد قسائم استُخدمت في الطلبات (فريدة).
  List<String> get usedCouponCodes {
    final codes = <String>{};
    for (final order in orders) {
      final code = order.couponCode?.trim();
      if (code != null && code.isNotEmpty) codes.add(code);
    }
    return codes.toList();
  }

  int get couponsCount => usedCouponCodes.length;

  bool get isDark => _theme.isDark;

  Future<void> setDarkMode(bool value) => _theme.setDarkMode(value);

  AppSettings get settings => _config.settings;

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email);
}
