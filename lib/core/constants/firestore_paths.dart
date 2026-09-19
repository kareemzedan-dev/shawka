/// مسارات Firestore المشتركة بين تطبيق العميل، الدليفري، الويب، ولوحة التحكم.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String stores = 'stores';
  static const String orders = 'orders';
  static const String governorates = 'governorates';
  static const String promoBanners = 'promo_banners';
  static const String storeCategories = 'store_categories';
  static const String appSettings = 'app_settings';
  static const String promotions = 'promotions';
  static const String pushCampaigns = 'push_campaigns';
  static const String auditLogs = 'audit_logs';
  static const String imageArchives = 'image_archives';
  static const String jobQueue = 'job_queue';
  static const String analyticsEvents = 'analytics_events';
  static const String cmsTexts = 'cms_texts';
  static const String customerActivityTypes = 'customer_activity_types';
  static const String rateLimits = 'rate_limits';
  static const String serviceAreaWaitlist = 'service_area_waitlist';
  static const String serviceAreaEvents = 'service_area_events';
  static const String deliveryPricingEvents = 'delivery_pricing_events';
  static const String reviews = 'reviews';

  static String storeProducts(String storeId) => '$stores/$storeId/products';
  static String appSettingsDoc(String docId) => '$appSettings/$docId';

  static String userSavedAddresses(String userId) =>
      '$users/$userId/saved_addresses';
  static String userFavorites(String userId) => '$users/$userId/favorites';

  static String governorateZones(String governorateId) =>
      '$governorates/$governorateId/zones';
}
