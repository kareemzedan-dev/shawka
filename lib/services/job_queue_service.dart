import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/domain/usecases/enqueue_job_use_case.dart';
import 'package:matlobgo/models/job_queue_entry.dart';

/// واجهة طابور المهام للتطبيق والأدمن.
class JobQueueService {
  JobQueueService._();

  static final JobQueueService instance = JobQueueService._();

  EnqueueJobUseCase get _enqueue => ServiceLocator.enqueueJob;

  Future<String> warmupCatalog(String governorate) =>
      _enqueue.catalogWarmup(governorate);

  Future<String> exportReport(Map<String, dynamic> spec) =>
      _enqueue.reportExport(spec);

  Stream<List<JobQueueEntry>> watchRecent({int limit = 30}) =>
      ServiceLocator.jobQueueRepository.watchRecent(limit: limit);
}
