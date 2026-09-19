abstract final class StoragePaths {
  static String storeLogo(String storeId) => 'stores/$storeId/logo.jpg';

  static String storeLogoThumb(String storeId) =>
      'stores/$storeId/logo_thumb.jpg';

  static String storeCover(String storeId) => 'stores/$storeId/cover.jpg';

  static String storeCoverThumb(String storeId) =>
      'stores/$storeId/cover_thumb.jpg';

  static String productImage(String storeId, String productId) =>
      'stores/$storeId/products/$productId/image.jpg';

  static String productImageThumb(String storeId, String productId) =>
      'stores/$storeId/products/$productId/image_thumb.jpg';

  static String promoBanner(String bannerId) =>
      'promo_banners/$bannerId/image.jpg';

  static String promoBannerThumb(String bannerId) =>
      'promo_banners/$bannerId/image_thumb.jpg';

  static String storeCategory(String governorateId, String categoryId) =>
      'store_categories/$governorateId/$categoryId/image.jpg';

  static String storeCategoryThumb(String governorateId, String categoryId) =>
      'store_categories/$governorateId/$categoryId/image_thumb.jpg';

  static String customerProof(String userId) =>
      'customers/$userId/proof.jpg';

  static String customerProofThumb(String userId) =>
      'customers/$userId/proof_thumb.jpg';
}
