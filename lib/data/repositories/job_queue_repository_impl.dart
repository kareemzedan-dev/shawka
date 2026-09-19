import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/domain/repositories/job_queue_repository.dart';
import 'package:matlobgo/models/job_queue_entry.dart';

class JobQueueRepositoryImpl implements JobQueueRepository {
  JobQueueRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.jobQueue);

  @override
  Future<String> enqueue({
    required JobType type,
    required Map<String, dynamic> payload,
    JobPriority priority = JobPriority.normal,
  }) async {
    final ref = _collection.doc();
    await ref.set(
      JobQueueEntry(
        id: ref.id,
        type: type,
        status: JobStatus.pending,
        priority: priority,
        payload: payload,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );
    return ref.id;
  }

  @override
  Stream<List<JobQueueEntry>> watchRecent({int limit = 30}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map(JobQueueEntry.fromFirestore).toList(),
        );
  }
}
