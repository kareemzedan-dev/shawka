/// أدوار الموظفين داخل لوحة التحكم — مخزّنة في Firestore.
enum AdminStaffRole {
  superAdmin,
  admin,
  manager,
  support,
  contentEditor,
  storeManager,
  /// مساعد تشغيل: تصنيفات + منتجات المتاجر + متابعة الطلبات.
  storeAssistant,
}

extension AdminStaffRoleX on AdminStaffRole {
  String get firestoreValue => name;

  String get label => switch (this) {
        AdminStaffRole.superAdmin => 'Super Admin',
        AdminStaffRole.admin => 'Admin',
        AdminStaffRole.manager => 'Manager',
        AdminStaffRole.support => 'Support',
        AdminStaffRole.contentEditor => 'Content Editor',
        AdminStaffRole.storeManager => 'صاحب متجر',
        AdminStaffRole.storeAssistant => 'مساعد تشغيل',
      };

  /// دور مقيّد بمتاجر محددة عبر managedStoreIds.
  bool get isStoreScoped => this == AdminStaffRole.storeManager;

  static AdminStaffRole fromFirestore(String? value) {
    if (value == null || value.isEmpty) return AdminStaffRole.admin;
    return AdminStaffRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => AdminStaffRole.admin,
    );
  }
}
