/// تبويبات الـ Shell الأساسية للتطبيق.
enum HomeTab { home, favorites, cart, orders, profile }

extension HomeTabX on HomeTab {
  String get id => name;

  String get analyticsScreen => switch (this) {
    HomeTab.home => 'tab_home',
    HomeTab.favorites => 'tab_favorites',
    HomeTab.cart => 'tab_cart',
    HomeTab.orders => 'tab_orders',
    HomeTab.profile => 'tab_profile',
  };

  String get defaultLabel => switch (this) {
    HomeTab.home => 'الرئيسية',
    HomeTab.favorites => 'المفضلة',
    HomeTab.cart => 'السلة',
    HomeTab.orders => 'طلباتي',
    HomeTab.profile => 'حسابي',
  };

  String get deepLinkPath => '/tab/$id';

  bool get isCore =>
      this == HomeTab.home ||
      this == HomeTab.cart ||
      this == HomeTab.orders ||
      this == HomeTab.profile;

  static HomeTab? tryParse(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return null;
    final normalized = value
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp(r'^tab/'), '')
        .replaceFirst(RegExp(r'^app/'), '');
    // توافق مع روابط/إعدادات قديمة كانت تستخدم search
    if (normalized == 'search') return HomeTab.favorites;
    for (final tab in HomeTab.values) {
      if (tab.id == normalized) return tab;
    }
    return null;
  }
}
