import 'package:flutter/material.dart';

enum AdminSection {
  overview,
  analytics,
  operations,
  liveMonitor,
  rescueOrders,
  incidents,
  /// طلبات تسجيل العملاء — أول عنصر ظاهر في مجموعة التشغيل.
  registrationRequests,
  categories,
  allStores,
  orders,
  customers,
  delivery,
  settlementRequests,
  promoBanners,
  promotions,
  reviews,
  mostOrdered,
  cmsTexts,
  searchPage,
  activityTypes,
  alerts,
  notifications,
  governorates,
  deliveryPricing,
  settings,
  roles,
  auditLogs,
  jobQueue,
}

extension AdminSectionX on AdminSection {
  String get title => switch (this) {
        AdminSection.overview => 'لوحة القيادة',
        AdminSection.analytics => 'التحليلات',
        AdminSection.operations => 'مركز العمليات',
        AdminSection.liveMonitor => 'المراقبة المباشرة',
        AdminSection.rescueOrders => 'Rescue Orders',
        AdminSection.incidents => 'مركز الأعطال',
        AdminSection.categories => 'التصنيفات',
        AdminSection.allStores => 'المتاجر',
        AdminSection.orders => 'الطلبات',
        AdminSection.customers => 'العملاء',
        AdminSection.registrationRequests => 'طلبات تسجيل العملاء',
        AdminSection.delivery => 'التوصيل',
        AdminSection.settlementRequests => 'طلبات التسوية',
        AdminSection.promoBanners => 'البانرات',
        AdminSection.promotions => 'العروض والخصومات',
        AdminSection.reviews => 'تقييمات العملاء',
        AdminSection.mostOrdered => 'الأكثر طلباً',
        AdminSection.cmsTexts => 'نصوص التطبيق',
        AdminSection.searchPage => 'صفحة البحث',
        AdminSection.activityTypes => 'أنواع النشاط',
        AdminSection.alerts => 'التنبيهات والبانر',
        AdminSection.notifications => 'الإشعارات',
        AdminSection.governorates => 'مناطق الخدمة',
        AdminSection.deliveryPricing => 'تكلفة التوصيل',
        AdminSection.settings => 'الإعدادات',
        AdminSection.roles => 'الصلاحيات',
        AdminSection.auditLogs => 'سجل العمليات',
        AdminSection.jobQueue => 'طابور المهام',
      };

  IconData get icon => switch (this) {
        AdminSection.overview => Icons.dashboard_rounded,
        AdminSection.analytics => Icons.insights_rounded,
        AdminSection.operations => Icons.hub_rounded,
        AdminSection.liveMonitor => Icons.sensors_rounded,
        AdminSection.rescueOrders => Icons.sos_rounded,
        AdminSection.incidents => Icons.report_problem_rounded,
        AdminSection.categories => Icons.category_rounded,
        AdminSection.allStores => Icons.store_mall_directory_rounded,
        AdminSection.orders => Icons.receipt_long_rounded,
        AdminSection.customers => Icons.people_rounded,
        AdminSection.registrationRequests => Icons.how_to_reg_rounded,
        AdminSection.delivery => Icons.delivery_dining_rounded,
        AdminSection.settlementRequests => Icons.request_quote_rounded,
        AdminSection.promoBanners => Icons.view_carousel_rounded,
        AdminSection.promotions => Icons.local_offer_rounded,
        AdminSection.reviews => Icons.reviews_rounded,
        AdminSection.mostOrdered => Icons.local_fire_department_rounded,
        AdminSection.cmsTexts => Icons.text_fields_rounded,
        AdminSection.searchPage => Icons.search_rounded,
        AdminSection.activityTypes => Icons.business_center_rounded,
        AdminSection.alerts => Icons.campaign_outlined,
        AdminSection.notifications => Icons.notifications_active_rounded,
        AdminSection.governorates => Icons.location_city_rounded,
        AdminSection.deliveryPricing => Icons.payments_outlined,
        AdminSection.settings => Icons.settings_rounded,
        AdminSection.roles => Icons.admin_panel_settings_rounded,
        AdminSection.auditLogs => Icons.history_rounded,
        AdminSection.jobQueue => Icons.queue_rounded,
      };

  String? get group => switch (this) {
        AdminSection.overview || AdminSection.analytics => 'القيادة',
        AdminSection.registrationRequests ||
        AdminSection.categories ||
        AdminSection.allStores ||
        AdminSection.orders ||
        AdminSection.customers =>
          'التشغيل',
        AdminSection.promoBanners ||
        AdminSection.promotions ||
        AdminSection.reviews ||
        AdminSection.mostOrdered ||
        AdminSection.cmsTexts ||
        AdminSection.searchPage ||
        AdminSection.activityTypes ||
        AdminSection.alerts ||
        AdminSection.notifications =>
          'المحتوى',
        AdminSection.governorates ||
        AdminSection.deliveryPricing ||
        AdminSection.settings ||
        AdminSection.roles ||
        AdminSection.auditLogs ||
        AdminSection.jobQueue =>
          'النظام',
        // أقسام المندوب المخفية — تبقى في enum لكن بلا مجموعة ظاهرة.
        _ => null,
      };

  bool get isStoreSection =>
      this == AdminSection.categories || this == AdminSection.allStores;

  bool get usesGovernorateFilter => switch (this) {
        AdminSection.overview ||
        AdminSection.analytics ||
        AdminSection.categories ||
        AdminSection.allStores ||
        AdminSection.orders ||
        AdminSection.promoBanners ||
        AdminSection.promotions ||
        AdminSection.mostOrdered ||
        AdminSection.roles =>
          true,
        _ => false,
      };

  /// أقسام منظومة المندوب — مخفية من الواجهة (يُبقى تكلفة التوصيل فقط).
  bool get isDriverFleetSection => switch (this) {
        AdminSection.delivery ||
        AdminSection.operations ||
        AdminSection.liveMonitor ||
        AdminSection.rescueOrders ||
        AdminSection.settlementRequests ||
        AdminSection.incidents =>
          true,
        _ => false,
      };
}
