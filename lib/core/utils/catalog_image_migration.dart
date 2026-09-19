import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';

/// In-memory + optional Firestore migration for `gs://` image fields.
abstract final class CatalogImageMigration {
  static const imageFields = <String>[
    'imageUrl',
    'imageThumbUrl',
    'coverUrl',
    'coverThumbUrl',
    'logoUrl',
    'logoThumbUrl',
  ];

  /// Normalize image fields on a Firestore document map (no write).
  static Map<String, dynamic> normalizeDocumentMap(Map<String, dynamic> data) {
    final out = Map<String, dynamic>.from(data);
    for (final field in imageFields) {
      final raw = out[field];
      if (raw is! String || raw.trim().isEmpty) continue;
      final normalized = CatalogImageUrlResolver.normalize(raw);
      if (normalized != null && normalized != raw) {
        out[field] = normalized;
      }
    }
    return out;
  }

  /// Returns fields that still need a Firestore write (`gs://` → https).
  static List<CatalogImageMigrationItem> pendingChanges(
    Map<String, dynamic> data,
  ) {
    final items = <CatalogImageMigrationItem>[];
    for (final field in imageFields) {
      final raw = data[field];
      if (raw is! String || !raw.trim().startsWith('gs://')) continue;
      final normalized = CatalogImageUrlResolver.normalize(raw);
      if (normalized == null) continue;
      items.add(
        CatalogImageMigrationItem(
          field: field,
          from: raw,
          to: normalized,
        ),
      );
    }
    return items;
  }

  /// Batch-migrate a collection's image URLs in Firestore (admin / one-off).
  static Future<CatalogImageMigrationReport> migrateCollection({
    required CollectionReference<Map<String, dynamic>> collection,
    int batchSize = 400,
    bool dryRun = true,
  }) async {
    final snapshot = await collection.get();
    var updatedDocs = 0;
    var updatedFields = 0;
    final samples = <String>[];

    WriteBatch? batch;
    var batchCount = 0;

    for (final doc in snapshot.docs) {
      final changes = pendingChanges(doc.data());
      if (changes.isEmpty) continue;

      if (!dryRun) {
        batch ??= FirebaseFirestore.instance.batch();
        final patch = <String, dynamic>{};
        for (final change in changes) {
          patch[change.field] = change.to;
        }
        batch.update(doc.reference, patch);
        batchCount++;
      }

      updatedDocs++;
      updatedFields += changes.length;
      if (samples.length < 10) {
        samples.add('${doc.id}: ${changes.first.field}');
      }

      if (!dryRun && batch != null && batchCount >= batchSize) {
        await batch.commit();
        batch = null;
        batchCount = 0;
      }
    }

    if (!dryRun && batch != null && batchCount > 0) {
      await batch.commit();
    }

    final report = CatalogImageMigrationReport(
      documentsScanned: snapshot.docs.length,
      documentsUpdated: updatedDocs,
      fieldsUpdated: updatedFields,
      dryRun: dryRun,
      sampleIds: samples,
    );

    if (kDebugMode) {
      debugPrint('[CatalogImageMigration] $report');
    }
    return report;
  }
}

class CatalogImageMigrationItem {
  const CatalogImageMigrationItem({
    required this.field,
    required this.from,
    required this.to,
  });

  final String field;
  final String from;
  final String to;
}

class CatalogImageMigrationReport {
  const CatalogImageMigrationReport({
    required this.documentsScanned,
    required this.documentsUpdated,
    required this.fieldsUpdated,
    required this.dryRun,
    required this.sampleIds,
  });

  final int documentsScanned;
  final int documentsUpdated;
  final int fieldsUpdated;
  final bool dryRun;
  final List<String> sampleIds;

  @override
  String toString() =>
      'scanned=$documentsScanned updated=$documentsUpdated '
      'fields=$fieldsUpdated dryRun=$dryRun samples=$sampleIds';
}
