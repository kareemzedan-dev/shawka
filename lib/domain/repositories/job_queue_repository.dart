import 'package:matlobgo/models/job_queue_entry.dart';

/// طابور مهام خلفية — يُعالَج على Cloud Functions (بديل Redis/Workers على Firebase).
abstract class JobQueueRepository {
  Future<String> enqueue({
    required JobType type,
    required Map<String, dynamic> payload,
    JobPriority priority = JobPriority.normal,
  });

  Stream<List<JobQueueEntry>> watchRecent({int limit});
}
