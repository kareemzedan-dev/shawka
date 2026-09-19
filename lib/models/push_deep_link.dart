/// مسارات Deep Link للإشعارات — تُمرَّر في FCM data.
enum PushDeepLinkRoute {
  none,
  home,
  search,
  cart,
  orders,
  profile,
  favorites,
  promotions,
  store,
  order,
}

extension PushDeepLinkRouteX on PushDeepLinkRoute {
  String get firestoreValue => name;

  String get label => switch (this) {
        PushDeepLinkRoute.none => 'بدون — الرئيسية',
        PushDeepLinkRoute.home => 'الرئيسية',
        PushDeepLinkRoute.search => 'بحث',
        PushDeepLinkRoute.cart => 'السلة',
        PushDeepLinkRoute.orders => 'طلباتي',
        PushDeepLinkRoute.profile => 'حسابي',
        PushDeepLinkRoute.favorites => 'المفضلة',
        PushDeepLinkRoute.promotions => 'العروض',
        PushDeepLinkRoute.store => 'متجر (يحتاج ID)',
        PushDeepLinkRoute.order => 'تتبع طلب (يحتاج ID)',
      };

  static PushDeepLinkRoute fromFirestore(String? value) {
    if (value == null || value.isEmpty) return PushDeepLinkRoute.none;
    return PushDeepLinkRoute.values.firstWhere(
      (r) => r.name == value,
      orElse: () => PushDeepLinkRoute.none,
    );
  }
}

class PushDeepLink {
  const PushDeepLink({required this.route, this.id = ''});

  final PushDeepLinkRoute route;
  final String id;

  factory PushDeepLink.fromFcmData(Map<String, dynamic> data) {
    return PushDeepLink(
      route: PushDeepLinkRouteX.fromFirestore(data['deepLink'] as String?),
      id: (data['deepLinkId'] as String? ?? '').trim(),
    );
  }
}
