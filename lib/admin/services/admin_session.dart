import 'package:matlobgo/admin/services/admin_audit_service.dart';
import 'package:matlobgo/admin/utils/audit_diff.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/audit_log.dart';

/// جلسة المدير الحالية — تُستخدم لتسجيل Audit Logs تلقائياً.
class AdminSession {
  AdminSession._();

  static final AdminSession instance = AdminSession._();

  final AdminAuditService audit = AdminAuditService();
  AppUser? user;

  void bind(AppUser? admin) {
    user = admin;
  }

  void clear() {
    user = null;
  }

  AdminStaffRole get staffRole =>
      user?.staffRole ?? AdminStaffRole.admin;

  /// صاحب متجر مقيّد بمتاجر معيّنة.
  bool get isStoreScoped => staffRole.isStoreScoped;

  List<String> get managedStoreIds =>
      List<String>.unmodifiable(user?.managedStoreIds ?? const []);

  bool canManageStore(String storeId) {
    final admin = user;
    if (admin == null) return false;
    return admin.canManageStore(storeId);
  }

  /// فلترة قائمة متاجر حسب صلاحية الجلسة.
  List<T> filterStores<T>(
    List<T> stores, {
    required String Function(T) idOf,
  }) {
    if (!isStoreScoped) return stores;
    final allowed = managedStoreIds.toSet();
    return stores.where((s) => allowed.contains(idOf(s))).toList();
  }

  bool get canCreateStores =>
      !isStoreScoped &&
      (staffRole == AdminStaffRole.superAdmin ||
          staffRole == AdminStaffRole.admin ||
          staffRole == AdminStaffRole.manager);

  bool get canDeleteStores => canCreateStores;

  Future<void> record({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String summary,
    Map<String, dynamic>? metadata,
  }) async {
    final actor = user;
    if (actor == null) return;
    await audit.log(
      actor: actor,
      action: action,
      entityType: entityType,
      entityId: entityId,
      summary: summary,
      metadata: metadata,
    );
  }

  /// تسجيل مع diff قبل/بعد — يُخزَّن في metadata.changes.
  Future<void> recordWithDiff({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String summary,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    Map<String, dynamic>? extraMetadata,
  }) async {
    final changes = AuditDiff.compute(before: before, after: after);
    final meta = <String, dynamic>{
      'before': ?before,
      'after': ?after,
      if (changes.isNotEmpty)
        'changes': changes
            .map(
              (c) => {
                'field': c.field,
                'before': c.before,
                'after': c.after,
              },
            )
            .toList(),
      ...?extraMetadata,
    };
    await record(
      action: action,
      entityType: entityType,
      entityId: entityId,
      summary: summary,
      metadata: meta.isEmpty ? null : meta,
    );
  }
}
