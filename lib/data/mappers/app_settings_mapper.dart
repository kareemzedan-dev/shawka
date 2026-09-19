import 'package:matlobgo/models/app_settings.dart';

abstract final class AppSettingsMapper {
  static AppSettings fromCacheJson(List<dynamic> json) {
    if (json.isEmpty) return const AppSettings();
    final first = json.first;
    if (first is! Map) return const AppSettings();
    final data = first['data'];
    if (data is! Map) return const AppSettings();
    return AppSettings.fromMap(Map<String, dynamic>.from(data));
  }

  static List<dynamic> toCacheJson(AppSettings settings) {
    return [
      {
        'id': AppSettings.documentId,
        'data': settings.toFirestore()..remove('updatedAt'),
      },
    ];
  }
}
