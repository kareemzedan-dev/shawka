import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/cache/cache_policy.dart';
import 'package:matlobgo/core/cache/cached_firestore_stream.dart';
import 'package:matlobgo/core/cache/firestore_cache_store.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/data/mappers/app_settings_mapper.dart';
import 'package:matlobgo/models/app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .doc(FirestorePaths.appSettingsDoc(AppSettings.documentId));

  Stream<AppSettings> watch() {
    final source = _doc.snapshots().map((snap) {
      if (!snap.exists) return const AppSettings();
      return AppSettings.fromFirestore(snap);
    });

    return cachedFirestoreStream<AppSettings>(
      cacheKey: CacheKeys.appSettings,
      policy: CachePolicy.appSettings,
      source: source,
      decode: AppSettingsMapper.fromCacheJson,
      encode: AppSettingsMapper.toCacheJson,
    );
  }

  Future<AppSettings> get() async {
    final snap = await _doc.get();
    if (!snap.exists) return const AppSettings();
    return AppSettings.fromFirestore(snap);
  }

  Future<void> save(AppSettings settings) {
    return _doc.set(settings.toFirestore(), SetOptions(merge: true));
  }
}
