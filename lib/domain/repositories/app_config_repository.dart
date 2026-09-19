import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/store.dart';

/// عقد إعدادات التطبيق والمحتوى العام.
abstract class AppConfigRepository {
  Stream<AppSettings> watchSettings();

  Future<AppSettings> getSettings();

  Stream<List<Governorate>> watchGovernorates();

  Stream<List<Governorate>> watchAvailableGovernorates();
}
