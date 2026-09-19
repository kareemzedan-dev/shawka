import 'package:matlobgo/domain/repositories/job_queue_repository.dart';
import 'package:matlobgo/models/job_queue_entry.dart';

/// Use case — إضافة مهمة لطابور Cloud Worker.
class EnqueueJobUseCase {
  EnqueueJobUseCase(this._repository);

  final JobQueueRepository _repository;

  Future<String> catalogWarmup(String governorate) {
    return _repository.enqueue(
      type: JobType.catalogWarmup,
      priority: JobPriority.low,
      payload: {'governorate': governorate},
    );
  }

  Future<String> analyticsBatch(Map<String, dynamic> events) {
    return _repository.enqueue(
      type: JobType.analyticsBatch,
      priority: JobPriority.normal,
      payload: events,
    );
  }

  Future<String> reportExport(Map<String, dynamic> spec) {
    return _repository.enqueue(
      type: JobType.reportExport,
      priority: JobPriority.high,
      payload: spec,
    );
  }
}
