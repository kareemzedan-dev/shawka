import 'package:matlobgo/admin/models/admin_section.dart';
import 'package:matlobgo/models/admin_staff_role.dart';

/// صلاحيات لوحة التحكم — تطابق firestore.rules و storage.rules حرفياً.
extension AdminStaffRolePermissions on AdminStaffRole {
  bool canAccess(AdminSection section) {
    return AdminPermissions.canAccess(this, section);
  }

  bool get isSuperOrAdmin =>
      this == AdminStaffRole.superAdmin || this == AdminStaffRole.admin;

  bool get canWriteStores => AdminPermissions.canWriteStores(this);
  bool get canCreateStores => AdminPermissions.canCreateStores(this);
  bool get canDeleteStores => AdminPermissions.canDeleteStores(this);
  bool get canWriteCategories => AdminPermissions.canWriteCategories(this);
  bool get canWritePromoBanners => AdminPermissions.canWritePromoBanners(this);
  bool get canWriteCmsTexts => AdminPermissions.canWriteCmsTexts(this);
  bool get canWriteActivityTypes =>
      AdminPermissions.canWriteActivityTypes(this);
  bool get canWritePromotions => AdminPermissions.canWritePromotions(this);
  bool get canWriteGovernorates => AdminPermissions.canWriteGovernorates(this);
  bool get canManageOrders => AdminPermissions.canManageOrders(this);
  bool get canReadAnalytics => AdminPermissions.canReadAnalytics(this);
  bool get canWriteAppSettings => AdminPermissions.canWriteAppSettings(this);
  bool get canManagePushCampaigns =>
      AdminPermissions.canManagePushCampaigns(this);
  bool get canReadAuditLogs => AdminPermissions.canReadAuditLogs(this);
  bool get canManageStaffRoles => AdminPermissions.canManageStaffRoles(this);
  bool get canManageDeliveryUsers =>
      AdminPermissions.canManageDeliveryUsers(this);
  bool get canReadUsersAsStaff => AdminPermissions.canReadUsersAsStaff(this);
}

abstract final class AdminPermissions {
  static bool canAccess(AdminStaffRole role, AdminSection section) {
    // منظومة المندوب مخفية بالكامل — الإبقاء على تكلفة التوصيل فقط.
    if (section.isDriverFleetSection) return false;

    if (role.isSuperOrAdmin) return true;

    return switch (role) {
      AdminStaffRole.manager => _managerSections.contains(section),
      AdminStaffRole.support => _supportSections.contains(section),
      AdminStaffRole.contentEditor => _contentSections.contains(section),
      AdminStaffRole.storeManager => _storeSections.contains(section),
      AdminStaffRole.storeAssistant => _assistantSections.contains(section),
      _ => false,
    };
  }

  static bool canWriteStores(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.storeManager ||
      role == AdminStaffRole.storeAssistant;

  /// إنشاء متجر جديد — للأدمن فقط (صاحب المتجر يُربَط بمتجر موجود).
  static bool canCreateStores(AdminStaffRole role) =>
      role.isSuperOrAdmin || role == AdminStaffRole.manager;

  static bool canDeleteStores(AdminStaffRole role) =>
      role.isSuperOrAdmin || role == AdminStaffRole.manager;

  static bool canWriteCategories(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.contentEditor ||
      role == AdminStaffRole.storeAssistant;

  static bool canWritePromoBanners(AdminStaffRole role) =>
      role.isSuperOrAdmin || role == AdminStaffRole.contentEditor;

  static bool canWriteCmsTexts(AdminStaffRole role) =>
      role.isSuperOrAdmin || role == AdminStaffRole.contentEditor;

  static bool canWriteActivityTypes(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.contentEditor;

  static bool canWritePromotions(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.contentEditor;

  static bool canWriteGovernorates(AdminStaffRole role) =>
      role.isSuperOrAdmin || role == AdminStaffRole.contentEditor;

  static bool canManageOrders(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.support ||
      role == AdminStaffRole.storeManager ||
      role == AdminStaffRole.storeAssistant;

  static bool canReadAnalytics(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.storeManager;

  static bool canWriteAppSettings(AdminStaffRole role) => role.isSuperOrAdmin;

  static bool canWriteAlerts(AdminStaffRole role) =>
      role.isSuperOrAdmin || role == AdminStaffRole.contentEditor;

  static bool canManagePushCampaigns(AdminStaffRole role) =>
      role.isSuperOrAdmin;

  static bool canReadAuditLogs(AdminStaffRole role) => role.isSuperOrAdmin;

  static bool canManageStaffRoles(AdminStaffRole role) => role.isSuperOrAdmin;

  static bool canManageDeliveryUsers(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.support;

  static bool canReadUsersAsStaff(AdminStaffRole role) =>
      role.isSuperOrAdmin ||
      role == AdminStaffRole.manager ||
      role == AdminStaffRole.support;

  static const _managerSections = {
    AdminSection.overview,
    AdminSection.analytics,
    AdminSection.orders,
    AdminSection.customers,
    AdminSection.registrationRequests,
    AdminSection.allStores,
    AdminSection.categories,
    AdminSection.activityTypes,
    AdminSection.promotions,
    AdminSection.reviews,
    AdminSection.mostOrdered,
    AdminSection.deliveryPricing,
    AdminSection.jobQueue,
  };

  static const _supportSections = {
    AdminSection.overview,
    AdminSection.orders,
    AdminSection.customers,
    AdminSection.registrationRequests,
    AdminSection.reviews,
  };

  static const _contentSections = {
    AdminSection.overview,
    AdminSection.promoBanners,
    AdminSection.categories,
    AdminSection.cmsTexts,
    AdminSection.searchPage,
    AdminSection.activityTypes,
    AdminSection.alerts,
    AdminSection.promotions,
    AdminSection.reviews,
    AdminSection.mostOrdered,
    AdminSection.governorates,
  };

  /// صاحب متجر: متجره + منتجاته + طلباته + إيراداته فقط.
  static const _storeSections = {
    AdminSection.analytics,
    AdminSection.allStores,
    AdminSection.orders,
  };

  /// مساعد تشغيل: تصنيفات + منتجات المتاجر + متابعة الطلبات.
  static const _assistantSections = {
    AdminSection.overview,
    AdminSection.categories,
    AdminSection.allStores,
    AdminSection.orders,
  };
}
