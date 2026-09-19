import 'package:matlobgo/data/repositories/app_config_repository_impl.dart';
import 'package:matlobgo/data/repositories/catalog_repository_impl.dart';
import 'package:matlobgo/data/repositories/job_queue_repository_impl.dart';
import 'package:matlobgo/domain/repositories/app_config_repository.dart';
import 'package:matlobgo/domain/repositories/catalog_repository.dart';
import 'package:matlobgo/domain/repositories/job_queue_repository.dart';
import 'package:matlobgo/domain/usecases/enqueue_job_use_case.dart';
import 'package:matlobgo/domain/usecases/watch_app_settings_use_case.dart';
import 'package:matlobgo/domain/usecases/watch_catalog_use_case.dart';

/// Composition Root — ربط Domain ← Data ← Infrastructure.
abstract final class ServiceLocator {
  static bool _ready = false;

  static late final CatalogRepository catalogRepository;
  static late final AppConfigRepository appConfigRepository;
  static late final JobQueueRepository jobQueueRepository;

  static late final WatchCatalogUseCase watchCatalog;
  static late final WatchAppSettingsUseCase watchAppSettings;
  static late final WatchGovernoratesUseCase watchGovernorates;
  static late final EnqueueJobUseCase enqueueJob;

  static Future<void> init() async {
    if (_ready) return;

    catalogRepository = CatalogRepositoryImpl();
    appConfigRepository = AppConfigRepositoryImpl();
    jobQueueRepository = JobQueueRepositoryImpl();

    watchCatalog = WatchCatalogUseCase(catalogRepository);
    watchAppSettings = WatchAppSettingsUseCase(appConfigRepository);
    watchGovernorates = WatchGovernoratesUseCase(appConfigRepository);
    enqueueJob = EnqueueJobUseCase(jobQueueRepository);

    _ready = true;
  }
}
