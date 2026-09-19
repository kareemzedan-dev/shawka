import 'package:matlobgo/config/branding/branding.dart';
import 'package:matlobgo/core/constants/app_branding.dart';

/// Web conversion & store links — branding from [Branding.current].
/// Hosting origin may remain on a technical Firebase domain until a custom
/// domain is configured in client.yaml (`support.website`).
abstract final class WebConstants {
  static String get siteName => AppBranding.shortName;
  static String get siteTagline => AppBranding.tagline;
  static String get canonicalOrigin => Branding.current.website;

  static String get googlePlayUrl =>
      'https://play.google.com/store/apps/details?id=${Branding.current.packageName}';
  static String get appStoreUrl =>
      'https://apps.apple.com/app/${Branding.current.clientId}/id0000000000';
  static String get appDeepLink => '${Branding.current.website}/open';

  static const cartDiscountThreshold = 100.0;
  static const storesVisitedPopupThreshold = 3;

  static const maxContentWidth = 1200.0;
  static const mobileBreakpoint = 720.0;

  static String governoratePath(String govId) => '/g/$govId';
  static String storesPath(String govId) => '/g/$govId/stores';
  static String profilePath(String govId) => '/g/$govId/profile';
  static String categoryPath(String govId, String categoryId) =>
      '/g/$govId/category/$categoryId';
  static String storePath(String storeId) => '/store/$storeId';
  static String productPath(String storeId, String productId) =>
      '/store/$storeId/product/$productId';

  static String shareDownloadMessage(String origin) =>
      AppBranding.downloadShareMessage(origin);
}
