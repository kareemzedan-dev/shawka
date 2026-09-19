import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  create,
  update,
  delete,
  statusChange,
  login,
  roleChange,
}

extension AuditActionX on AuditAction {
  String get firestoreValue => name;

  String get label => switch (this) {
        AuditAction.create => 'إنشاء',
        AuditAction.update => 'تعديل',
        AuditAction.delete => 'حذف',
        AuditAction.statusChange => 'تغيير حالة',
        AuditAction.login => 'دخول',
        AuditAction.roleChange => 'تغيير صلاحية',
      };

  static AuditAction fromFirestore(String? value) {
    return AuditAction.values.firstWhere(
      (a) => a.name == value,
      orElse: () => AuditAction.update,
    );
  }
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.summary,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String actorId;
  final String actorName;
  final AuditAction action;
  final String entityType;
  final String entityId;
  final String summary;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  factory AuditLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AuditLog(
      id: doc.id,
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      action: AuditActionX.fromFirestore(data['action'] as String?),
      entityType: data['entityType'] as String? ?? '',
      entityId: data['entityId'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'action': action.firestoreValue,
      'entityType': entityType,
      'entityId': entityId,
      'summary': summary,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
