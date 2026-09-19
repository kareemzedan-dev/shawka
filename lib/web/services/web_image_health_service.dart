import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/utils/catalog_image_diagnostics.dart';
import 'package:matlobgo/core/utils/catalog_image_health_checker.dart';

/// Background catalog image audit for MatlobGo Web (console diagnostics).
abstract final class WebImageHealthService {
  static bool _ran = false;

  static Future<void> runStartupAuditIfEnabled() async {
    if (_ran) return;
    _ran = true;

    final audit =
        kDebugMode ||
        bool.fromEnvironment('CATALOG_IMAGE_AUDIT', defaultValue: false);
    if (!audit) return;

    CatalogImageDiagnostics.enabled = true;
    CatalogImageDiagnostics.resetCounters();

    try {
      final urls = await _collectCatalogUrls();
      final report = await CatalogImageHealthChecker.check(urls);
      CatalogImageHealthChecker.logReport(report);
      CatalogImageDiagnostics.printSummary();
    } catch (error, stackTrace) {
      debugPrint('[WebImageHealth] audit failed: $error\n$stackTrace');
    }
  }

  static Future<List<String?>> _collectCatalogUrls() async {
    final db = FirebaseFirestore.instance;
    final urls = <String?>[];

    final banners = await db.collection('promo_banners').limit(40).get();
    for (final doc in banners.docs) {
      final data = doc.data();
      urls.add(data['imageUrl'] as String?);
      urls.add(data['imageThumbUrl'] as String?);
    }

    final stores = await db.collection('stores').limit(80).get();
    for (final doc in stores.docs) {
      final data = doc.data();
      for (final key in [
        'imageUrl',
        'imageThumbUrl',
        'coverUrl',
        'coverThumbUrl',
        'logoUrl',
        'logoThumbUrl',
      ]) {
        urls.add(data[key] as String?);
      }
    }

    final categories = await db.collection('store_categories').limit(60).get();
    for (final doc in categories.docs) {
      final data = doc.data();
      urls.add(data['imageUrl'] as String?);
      urls.add(data['imageThumbUrl'] as String?);
    }

    return urls;
  }
}
