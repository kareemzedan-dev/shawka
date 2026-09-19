import 'package:cloud_firestore/cloud_firestore.dart';

enum JobType {
  analyticsBatch,
  catalogWarmup,
  pushRetry,
  reportExport,
}

enum JobPriority {
  low,
  normal,
  high,
}

enum JobStatus {
  pending,
  processing,
  completed,
  failed,
}

extension JobTypeX on JobType {
  String get firestoreValue => name;
  static JobType fromFirestore(String? v) =>
      JobType.values.firstWhere((e) => e.name == v, orElse: () => JobType.catalogWarmup);
}

extension JobPriorityX on JobPriority {
  String get firestoreValue => name;
  static JobPriority fromFirestore(String? v) =>
      JobPriority.values.firstWhere((e) => e.name == v, orElse: () => JobPriority.normal);
}

extension JobStatusX on JobStatus {
  String get firestoreValue => name;
  static JobStatus fromFirestore(String? v) =>
      JobStatus.values.firstWhere((e) => e.name == v, orElse: () => JobStatus.pending);
}

class JobQueueEntry {
  const JobQueueEntry({
    required this.id,
    required this.type,
    required this.status,
    required this.priority,
    required this.payload,
    required this.createdAt,
    this.completedAt,
    this.error,
    this.attempts = 0,
  });

  final String id;
  final JobType type;
  final JobStatus status;
  final JobPriority priority;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? error;
  final int attempts;

  factory JobQueueEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return JobQueueEntry(
      id: doc.id,
      type: JobTypeX.fromFirestore(data['type'] as String?),
      status: JobStatusX.fromFirestore(data['status'] as String?),
      priority: JobPriorityX.fromFirestore(data['priority'] as String?),
      payload: Map<String, dynamic>.from(data['payload'] as Map? ?? {}),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      error: data['error'] as String?,
      attempts: data['attempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.firestoreValue,
      'status': status.firestoreValue,
      'priority': priority.firestoreValue,
      'payload': payload,
      'attempts': attempts,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
