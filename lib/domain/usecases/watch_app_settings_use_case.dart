import 'package:matlobgo/domain/repositories/app_config_repository.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/store.dart';

class WatchAppSettingsUseCase {
  WatchAppSettingsUseCase(this._repository);

  final AppConfigRepository _repository;

  Stream<AppSettings> call() => _repository.watchSettings();
}

class WatchGovernoratesUseCase {
  WatchGovernoratesUseCase(this._repository);

  final AppConfigRepository _repository;

  Stream<List<Governorate>> available() => _repository.watchAvailableGovernorates();

  Stream<List<Governorate>> all() => _repository.watchGovernorates();
}
