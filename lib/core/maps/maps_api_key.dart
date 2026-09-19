import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/maps/google_maps_web_loader.dart';
import 'package:matlobgo/core/utils/platform_info.dart';
import 'package:flutter/services.dart';

/// مفتاح واجهات Google (Places / Directions / Geocoding) — لا يُسجَّل في الـ logs.
abstract final class MapsApiKey {
  static String? _cached;

  static const _androidDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_ANDROID',
    defaultValue: '',
  );
  static const _iosDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_IOS',
    defaultValue: '',
  );
  static const _legacyDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static Future<String> resolve() async {
    if (_cached != null) return _cached!;

    if (!kIsWeb) {
      if (platformIsAndroid && _androidDefine.isNotEmpty) {
        return _cache(_androidDefine);
      }
      if (platformIsIOS && _iosDefine.isNotEmpty) {
        return _cache(_iosDefine);
      }
    }
    if (_legacyDefine.isNotEmpty) {
      return _cache(_legacyDefine);
    }

    try {
      final raw = await rootBundle.loadString('assets/secrets/maps_keys.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final key = kIsWeb
          ? (map['web'] as String? ??
              map['android'] as String? ??
              map['ios'] as String? ??
              '')
          : platformIsIOS
              ? (map['ios'] as String? ?? '')
              : (map['android'] as String? ?? '');
      if (key.trim().isNotEmpty) {
        return _cache(key.trim());
      }
    } catch (_) {
      // ملف غير موجود — شغّل scripts/configure-google-maps.ps1
    }

    return _cache('');
  }

  static String _cache(String value) {
    _cached = value;
    return value;
  }

  static bool get isReady => _cached != null && _cached!.isNotEmpty;

  /// تهيئة عند بدء التطبيق (اختياري لكن مُوصى به).
  /// على الويب يحمّل أيضاً سكربت Maps JavaScript API.
  static Future<void> warmUp() async {
    final key = await resolve();
    if (kIsWeb && key.isNotEmpty) {
      await ensureGoogleMapsJsLoaded(key);
    }
  }
}
