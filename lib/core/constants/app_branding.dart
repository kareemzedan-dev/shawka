import 'package:matlobgo/config/branding/branding.dart';

/// User-facing brand identity — facade over [Branding.current].
///
/// Technical identifiers (Dart package name `matlobgo`) stay unchanged.
abstract final class AppBranding {
  static BrandingData get _b => Branding.current;

  static String get displayName => _b.displayName;
  static String get shortName => _b.shortName;
  static String get nameEn => _b.nameEn;
  static String get nameAr => _b.nameAr;
  static String get tagline => _b.tagline;
  static String get adminPanelTitle => _b.adminPanelTitle;
  static String get driverAppName => _b.driverAppName;
  static String get loadingMessage => _b.loadingMessage;
  static String get supportEmail => _b.supportEmail;
  static String get supportPhone => _b.supportPhone;
  static String get website => _b.website;
  static String get supportEmailMailto => _b.supportEmailMailto;

  static String get aboutDescription => _b.aboutDescription;
  static String get locationPermissionRationale =>
      _b.locationPermissionRationale;
  static String get joinPageTitle => _b.joinPageTitle;
  static String get notificationsInAppMessage => _b.notificationsInAppMessage;
  static String get completeOrderInAppMessage => _b.completeOrderInAppMessage;
  static String get cartSeoDescription => _b.cartSeoDescription;

  static String downloadShareMessage(String origin) =>
      _b.downloadShareMessage(origin);

  static String liveDataFromBrand(String governorate) =>
      _b.liveDataFromBrand(governorate);

  static String categorySeoDescription(String categoryId, String govName) =>
      _b.categorySeoDescription(categoryId, govName);
}
