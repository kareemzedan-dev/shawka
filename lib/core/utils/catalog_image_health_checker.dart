import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/utils/catalog_image_diagnostics.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';

/// Batch HTTP probe for catalog image URLs (missing files, CORS, permissions).
abstract final class CatalogImageHealthChecker {
  static Future<CatalogImageHealthReport> check(
    Iterable<String?> rawUrls, {
    String tag = 'health-check',
    int concurrency = 6,
  }) async {
    final urls = <String>{};
    for (final raw in rawUrls) {
      for (final candidate in CatalogImageUrlResolver.candidateUrls(
        imageUrl: raw,
      )) {
        urls.add(candidate);
      }
    }

    final results = <CatalogImageProbeResult>[];
    final list = urls.toList();
    var index = 0;

    Future<void> worker() async {
      while (index < list.length) {
        final i = index++;
        results.add(
          await CatalogImageDiagnostics.probeUrl(list[i], tag: tag),
        );
      }
    }

    final workers = List.generate(
      concurrency.clamp(1, list.length.clamp(1, 12)),
      (_) => worker(),
    );
    await Future.wait(workers);

    final ok = results.where((r) => r.ok).length;
    final broken = results.length - ok;
    final cors = results.where((r) => r.isLikelyCors).length;
    final missing = results
        .where((r) => r.statusCode == 404 || (r.error?.contains('404') ?? false))
        .length;
    final forbidden = results.where((r) => r.statusCode == 403).length;

    return CatalogImageHealthReport(
      total: results.length,
      ok: ok,
      broken: broken,
      likelyCors: cors,
      missingFiles: missing,
      permissionDenied: forbidden,
      results: results,
    );
  }

  static void logReport(CatalogImageHealthReport report) {
    if (!kDebugMode && !CatalogImageDiagnostics.enabled) return;
    debugPrint(
      '[CatalogImageHealth] total=${report.total} ok=${report.ok} '
      'broken=${report.broken} missing=${report.missingFiles} '
      'cors=${report.likelyCors} forbidden=${report.permissionDenied} '
      'successRate=${(report.successRate * 100).toStringAsFixed(1)}%',
    );
    for (final fail in report.failures.take(25)) {
      debugPrint(
        '  ✗ ${fail.statusCode ?? 'ERR'} ${fail.url} '
        '${fail.error ?? fail.reasonPhrase ?? ''}',
      );
    }
  }
}

class CatalogImageHealthReport {
  const CatalogImageHealthReport({
    required this.total,
    required this.ok,
    required this.broken,
    required this.likelyCors,
    required this.missingFiles,
    required this.permissionDenied,
    required this.results,
  });

  final int total;
  final int ok;
  final int broken;
  final int likelyCors;
  final int missingFiles;
  final int permissionDenied;
  final List<CatalogImageProbeResult> results;

  double get successRate => total == 0 ? 0 : ok / total;

  List<CatalogImageProbeResult> get failures =>
      results.where((r) => !r.ok).toList();
}
