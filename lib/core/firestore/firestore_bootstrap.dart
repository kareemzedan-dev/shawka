import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/cache/firestore_cache_store.dart';

/// تهيئة Firestore للأداء: persistence + كاش التطبيق.
abstract final class FirestoreBootstrap {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final firestore = FirebaseFirestore.instance;
    firestore.settings = Settings(
      persistenceEnabled: !kIsWeb,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await FirestoreCacheStore.instance.init();
  }
}
