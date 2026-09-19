import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/repositories/profile_repository.dart';
import 'package:matlobgo/screens/home/widgets/profile_widgets.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/notification_service.dart';

enum ProfileUiPhase { loading, guest, ready, offline, error }

/// حالة شاشة حسابي — UI يعتمد عليها فقط (RI v8).
class ProfileController extends ChangeNotifier {
  ProfileController({
    required AppUser? user,
    required this.notificationService,
    required this.governorateName,
    required AuthService authService,
    ProfileRepository? repository,
  })  : _user = user,
        _repo = repository ??
            ProfileRepository(authService: authService) {
    _listenable = _repo.dataListenable;
    _listenable.addListener(_onData);
    unawaited(_trackOpen());
  }

  final NotificationService notificationService;
  final String governorateName;
  final ProfileRepository _repo;
  late final Listenable _listenable;

  AppUser? _user;
  String? _notice;
  bool _offline = false;

  AppUser? get user => _user;
  String? get notice => _notice;
  bool get offline => _offline;
  bool get isGuest => _user?.isGuest ?? true;
  bool get isDark => _repo.isDark;
  AppSettings get settings => _repo.settings;
  int get unreadNotifications => notificationService.unreadCount;

  int get ordersCount => _repo.ordersCount;
  int get favoritesCount => _repo.favoritesCount;
  int get addressesCount =>
      _repo.addressCount(governorate: _user?.governorate ?? governorateName);
  int get couponsCount => _repo.couponsCount;
  List<String> get usedCouponCodes => _repo.usedCouponCodes;
  Order? get lastOrder => _repo.lastOrder;

  String get displayName =>
      (_user?.name.trim().isNotEmpty == true) ? _user!.name.trim() : 'ضيف';
  String get email => _user?.email.trim() ?? '';
  String get phone => _user?.phone.trim() ?? '';
  String get initials => profileInitials(displayName);

  String get membershipLabel {
    final tier = profileMembershipTier(
      isGuest: isGuest,
      ordersCount: ordersCount,
      joinDate: _user?.createdAt,
    );
    return switch (tier) {
      ProfileMembershipTier.guest => 'زائر',
      ProfileMembershipTier.active => 'عضو ${AppBranding.shortName}',
      ProfileMembershipTier.gold => 'عضو ${AppBranding.shortName} Plus',
    };
  }

  ProfileUiPhase get phase {
    if (_offline) return ProfileUiPhase.offline;
    if (isGuest) return ProfileUiPhase.guest;
    return ProfileUiPhase.ready;
  }

  void updateUser(AppUser? user) {
    if (_user?.uid == user?.uid &&
        _user?.name == user?.name &&
        _user?.email == user?.email &&
        _user?.phone == user?.phone &&
        _user?.governorate == user?.governorate &&
        _user?.isGuest == user?.isGuest) {
      return;
    }
    _user = user;
    notifyListeners();
  }

  void _onData() => notifyListeners();

  void clearNotice() => _notice = null;

  Future<void> setDarkMode(bool value) async {
    await _repo.setDarkMode(value);
    notifyListeners();
  }

  Future<void> logout() => _repo.signOut();

  Future<void> sendPasswordReset() async {
    final mail = email;
    if (mail.isEmpty) {
      _notice = 'لا يوجد بريد مرتبط بالحساب';
      notifyListeners();
      return;
    }
    try {
      await _repo.sendPasswordReset(mail);
      _notice = 'تم إرسال رابط استعادة كلمة المرور إلى بريدك';
      _offline = false;
    } catch (_) {
      _offline = true;
      _notice = 'تعذّر إرسال رابط الاستعادة — تحقق من الاتصال';
    }
    notifyListeners();
  }

  String inviteShareText(String origin) =>
      AppBranding.downloadShareMessage(origin);

  Future<void> _trackOpen() => AnalyticsService.instance.screenView(
        screen: 'profile',
        label: 'حسابي',
      );

  @override
  void dispose() {
    _listenable.removeListener(_onData);
    super.dispose();
  }
}

/// تنسيق وقت آخر نشاط للعرض.
abstract final class ProfileActivityFormat {
  static String relativeTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final clock = _clock(local);
    if (day == today) return 'اليوم $clock';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس $clock';
    return '${local.day}/${local.month}/${local.year} $clock';
  }

  static String _clock(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  static String price(Order order) =>
      '${order.grandTotal.toStringAsFixed(2)} ج.م';

  static String title(Order order) => 'طلب — ${order.storeName}';
}
