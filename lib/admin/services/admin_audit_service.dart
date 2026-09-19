import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/repositories/audit_log_repository.dart';

class AdminAuditService {
  AdminAuditService({
    AuditLogRepository? repository,
  }) : _repository = repository ?? AuditLogRepository();

  final AuditLogRepository _repository;

  Future<void> log({
    required AppUser actor,
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String summary,
    Map<String, dynamic>? metadata,
  }) {
    return _repository.log(
      AuditLog(
        id: '',
        actorId: actor.uid,
        actorName: actor.name.isEmpty ? actor.email : actor.name,
        action: action,
        entityType: entityType,
        entityId: entityId,
        summary: summary,
        createdAt: DateTime.now(),
        metadata: metadata ?? const {},
      ),
    );
  }
}
