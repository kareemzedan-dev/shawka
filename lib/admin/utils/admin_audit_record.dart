import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/audit_diff.dart';
import 'package:matlobgo/models/audit_log.dart';

/// تسجيل audit موحّد مع diff — يُستخدم من نماذج الأدمن.
abstract final class AdminAuditRecord {
  static Future<void> firestoreEntity({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String summary,
    Map<String, dynamic>? beforeFirestore,
    Map<String, dynamic>? afterFirestore,
    Map<String, dynamic>? extraMetadata,
  }) {
    return AdminSession.instance.recordWithDiff(
      action: action,
      entityType: entityType,
      entityId: entityId,
      summary: summary,
      before: beforeFirestore != null
          ? AuditDiff.snapshot(beforeFirestore)
          : null,
      after: afterFirestore != null
          ? AuditDiff.snapshot(afterFirestore)
          : null,
      extraMetadata: extraMetadata,
    );
  }

  static Future<void> fields({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String summary,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) {
    return AdminSession.instance.recordWithDiff(
      action: action,
      entityType: entityType,
      entityId: entityId,
      summary: summary,
      before: before,
      after: after,
    );
  }
}
