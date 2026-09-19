import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// L1 ذاكرة + L2 SharedPreferences — بيانات Firestore مجمّعة كـ JSON.
class FirestoreCacheStore {
  FirestoreCacheStore._();

  static final FirestoreCacheStore instance = FirestoreCacheStore._();

  final Map<String, _MemoryEntry> _memory = {};
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<T?> read<T>({
    required String key,
    required T Function(List<dynamic> json) decode,
    required Duration maxAge,
    bool allowDisk = true,
  }) async {
    final now = DateTime.now();
    final mem = _memory[key];
    if (mem != null && now.difference(mem.storedAt) <= maxAge) {
      return decode(mem.payload);
    }

    if (!allowDisk) return null;
    await init();
    final raw = _prefs!.getString('fs_cache:$key');
    final atMs = _prefs!.getInt('fs_cache_at:$key');
    if (raw == null || atMs == null) return null;

    final storedAt = DateTime.fromMillisecondsSinceEpoch(atMs);
    if (now.difference(storedAt) > maxAge) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final value = decode(list);
      _memory[key] = _MemoryEntry(list, storedAt);
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> write<T>({
    required String key,
    required T value,
    required List<dynamic> Function(T value) encode,
  }) async {
    final payload = encode(value);
    final now = DateTime.now();
    _memory[key] = _MemoryEntry(payload, now);

    await init();
    await _prefs!.setString('fs_cache:$key', jsonEncode(payload));
    await _prefs!.setInt('fs_cache_at:$key', now.millisecondsSinceEpoch);
  }

  void invalidate(String keyPrefix) {
    _memory.removeWhere((k, _) => k.startsWith(keyPrefix));
    if (_prefs == null) return;
    final keys = _prefs!
        .getKeys()
        .where((k) => k.startsWith('fs_cache:$keyPrefix'))
        .toList();
    for (final k in keys) {
      _prefs!.remove(k);
      _prefs!.remove(k.replaceFirst('fs_cache:', 'fs_cache_at:'));
    }
  }

  Future<void> clearAll() async {
    _memory.clear();
    await init();
    final keys = _prefs!.getKeys().where((k) => k.startsWith('fs_cache'));
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }
}

class _MemoryEntry {
  _MemoryEntry(this.payload, this.storedAt);
  final List<dynamic> payload;
  final DateTime storedAt;
}

abstract final class CacheKeys {
  static String stores(String governorate, String? categoryId) =>
      'stores:$governorate:${categoryId ?? 'all'}';

  static String categories(String governorate) => 'categories:$governorate';

  static String products(String storeId) => 'products:$storeId';

  static String appSettings = 'app_settings:config';

  static String governorates = 'governorates:all';

  static String promoBanners(String governorate) => 'banners:$governorate';
}
