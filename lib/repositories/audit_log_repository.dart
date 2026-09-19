import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/audit_log.dart';

class AuditLogRepository {
  AuditLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.auditLogs);

  Stream<List<AuditLog>> watchRecent({int limit = 100}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map(AuditLog.fromFirestore).toList(),
        );
  }

  Future<void> log(AuditLog entry) {
    final ref = _collection.doc();
    return ref.set(entry.toFirestore());
  }
}
