import 'package:flutter/material.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';

/// Central White Label branding API.
///
/// Values are compile-time constants from `tool/generate_brand.dart`.
/// Prefer `AppBranding` / `AppColors` facades for existing call sites.
abstract final class Branding {
  static final BrandingData current = BrandingData.fromGenerated();
}

@immutable
class BrandingData {
  const BrandingData({
    required this.clientId,
    required this.version,
    required this.schemaVersion,
    required this.appName,
    required this.companyName,
    required this.packageName,
    required this.bundleId,
    required this.tagline,
    required this.adminPanelTitle,
    required this.driverAppName,
    required this.firebaseProjectId,
    required this.firebaseRegion,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.accent,
    required this.primaryHex,
    required this.secondaryHex,
    required this.supportEmail,
    required this.supportPhone,
    required this.website,
    required this.address,
    required this.paymob,
    required this.stripe,
    required this.cash,
    required this.mapsProvider,
    required this.featureDelivery,
    required this.featurePharmacy,
    required this.featureGroceries,
    required this.featureWallet,
    required this.featureCoupons,
    required this.featureSubscriptions,
    required this.featureLoyalty,
    required this.featureMarketplace,
    required this.logoAsset,
    required this.splashAsset,
    required this.faviconAsset,
  });

  factory BrandingData.fromGenerated() => const BrandingData(
    clientId: BrandingValues.clientId,
    version: BrandingValues.version,
    schemaVersion: BrandingValues.schemaVersion,
    appName: BrandingValues.appName,
    companyName: BrandingValues.companyName,
    packageName: BrandingValues.packageName,
    bundleId: BrandingValues.bundleId,
    tagline: BrandingValues.tagline,
    adminPanelTitle: BrandingValues.adminPanelTitle,
    driverAppName: BrandingValues.driverAppName,
    firebaseProjectId: BrandingValues.firebaseProjectId,
    firebaseRegion: BrandingValues.firebaseRegion,
    primary: Color(BrandingValues.primaryValue),
    primaryDark: Color(BrandingValues.primaryDarkValue),
    primaryLight: Color(BrandingValues.primaryLightValue),
    secondary: Color(BrandingValues.secondaryValue),
    secondaryLight: Color(BrandingValues.secondaryLightValue),
    accent: Color(BrandingValues.accentValue),
    primaryHex: BrandingValues.primaryHex,
    secondaryHex: BrandingValues.secondaryHex,
    supportEmail: BrandingValues.supportEmail,
    supportPhone: BrandingValues.supportPhone,
    website: BrandingValues.website,
    address: BrandingValues.address,
    paymob: BrandingValues.paymob,
    stripe: BrandingValues.stripe,
    cash: BrandingValues.cash,
    mapsProvider: BrandingValues.mapsProvider,
    featureDelivery: BrandingValues.featureDelivery,
    featurePharmacy: BrandingValues.featurePharmacy,
    featureGroceries: BrandingValues.featureGroceries,
    featureWallet: BrandingValues.featureWallet,
    featureCoupons: BrandingValues.featureCoupons,
    featureSubscriptions: BrandingValues.featureSubscriptions,
    featureLoyalty: BrandingValues.featureLoyalty,
    featureMarketplace: BrandingValues.featureMarketplace,
    logoAsset: BrandingValues.logoAsset,
    splashAsset: BrandingValues.splashAsset,
    faviconAsset: BrandingValues.faviconAsset,
  );

  final String clientId;
  final String version;
  final int schemaVersion;
  final String appName;
  final String companyName;
  final String packageName;
  final String bundleId;
  final String tagline;
  final String adminPanelTitle;
  final String driverAppName;
  final String firebaseProjectId;
  final String firebaseRegion;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color secondaryLight;
  final Color accent;
  final String primaryHex;
  final String secondaryHex;
  final String supportEmail;
  final String supportPhone;
  final String website;
  final String address;
  final bool paymob;
  final bool stripe;
  final bool cash;
  final String mapsProvider;
  final bool featureDelivery;
  final bool featurePharmacy;
  final bool featureGroceries;
  final bool featureWallet;
  final bool featureCoupons;
  final bool featureSubscriptions;
  final bool featureLoyalty;
  final bool featureMarketplace;
  final String logoAsset;
  final String splashAsset;
  final String faviconAsset;

  String get displayName => appName;
  String get shortName {
    final pipe = appName.indexOf('|');
    if (pipe > 0) return appName.substring(0, pipe).trim();
    return appName;
  }

  String get nameEn => 'Shawka & Skeena';
  String get nameAr => 'شوكة و سكينة';

  String get supportEmailMailto => 'mailto:$supportEmail';
  String get supportPhoneTel => 'tel:$supportPhone';

  String get aboutDescription =>
      '$nameAr — منصتك الموثوقة للطلب من موردي المواد الغذائية '
      'وشركات التوريد في محافظتك.\n\n'
      'توصيل سريع، تتبع مباشر، وتجربة راقية من الشوكة إلى الباب.';

  String get locationPermissionRationale =>
      '$appName يحتاج موقعك لعرض المتاجر القريبة وتتبع التوصيل.';

  String get joinPageTitle => 'انضم لـ $appName';

  String get notificationsInAppMessage => 'الإشعارات متاحة في تطبيق $appName';

  String get completeOrderInAppMessage => 'أكمل طلبك عبر تطبيق $appName';

  String get cartSeoDescription => 'راجع طلبك وأكمله عبر تطبيق $appName.';

  String get loadingMessage => 'جاري التحميل...';

  String downloadShareMessage(String origin) =>
      'حمّل تطبيق $shortName واطلب بسهولة مع تتبع مباشر وعروض حصرية: $origin';

  String liveDataFromBrand(String governorate) =>
      'اكتشف أفضل موردي المواد الغذائية في $governorate — بيانات حية من $shortName.';

  String categorySeoDescription(String categoryId, String govName) =>
      'موردون في تصنيف $categoryId في $govName على $shortName.';
}
