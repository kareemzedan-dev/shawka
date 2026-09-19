import 'package:matlobgo/config/branding/generated/branding_values.g.dart';

abstract final class AppAssets {
  /// Prefer White Label current logo.
  static const String logo = BrandingValues.logoAsset;

  /// Auth / marketing surfaces — cream plate mark (`loogo`).
  static const String authLogo = 'assets/images/loogo.jpeg';

  static const String categoryAll = 'assets/images/categories/all.jpg';

  /// Fallback image used for any store/category card that doesn't have a
  /// dedicated image (suppliers are no longer split into sub-categories).
  static const String categoryFallback = categoryAll;

  static const String bannerDelivery = 'assets/images/banners/delivery.jpg';
  static const String bannerDiscount = 'assets/images/banners/discount.jpg';
  static const String bannerPharmacy = 'assets/images/banners/pharmacy.jpg';
}
