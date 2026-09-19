import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/domain/repositories/app_config_repository.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/app_settings_repository.dart';
import 'package:matlobgo/repositories/governorate_repository.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  AppConfigRepositoryImpl({
    AppSettingsRepository? settings,
    GovernorateRepository? governorates,
  })  : _settings = settings ?? AppSettingsRepository(),
        _governorates = governorates ?? GovernorateRepository();

  final AppSettingsRepository _settings;
  final GovernorateRepository _governorates;

  @override
  Stream<AppSettings> watchSettings() => _settings.watch();

  @override
  Future<AppSettings> getSettings() => _settings.get();

  @override
  Stream<List<Governorate>> watchGovernorates() {
    return _governorates.watchAll().map((list) {
      if (list.isEmpty) return EgyptGovernorates.all;
      return list;
    });
  }

  @override
  Stream<List<Governorate>> watchAvailableGovernorates() {
    return _governorates.watchAvailable().map((list) {
      if (list.isEmpty) return EgyptGovernorates.available;
      return list;
    });
  }
}
