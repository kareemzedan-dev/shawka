import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Debug telemetry for catalog image loads (web + mobile).
abstract final class CatalogImageDiagnostics {
  static bool enabled = kDebugMode ||
      bool.fromEnvironment('CATALOG_IMAGE_DEBUG', defaultValue: false);

  static int successCount = 0;
  static int failureCount = 0;
  static int probeOkCount = 0;
  static int probeFailCount = 0;

  static final List<CatalogImageLoadEvent> _recent = [];
  static const _maxRecent = 200;

  static UnmodifiableListView<CatalogImageLoadEvent> get recentEvents =>
      UnmodifiableListView(_recent);

  static double get loadSuccessRate {
    final total = successCount + failureCount;
    if (total == 0) return 0;
    return successCount / total;
  }

  static void resetCounters() {
    successCount = 0;
    failureCount = 0;
    probeOkCount = 0;
    probeFailCount = 0;
    _recent.clear();
  }

  static void logAttempt({
    required String? url,
    String tag = 'CatalogNetworkImage',
    String? candidateIndex,
  }) {
    if (!enabled || url == null || url.isEmpty) return;
    _emit(
      CatalogImageLoadEvent(
        url: url,
        tag: tag,
        phase: CatalogImageLoadPhase.attempt,
        message: candidateIndex == null ? null : 'candidate $candidateIndex',
      ),
    );
  }

  static void logSuccess({
    required String? url,
    String tag = 'CatalogNetworkImage',
    int? httpStatus,
  }) {
    if (url == null || url.isEmpty) return;
    successCount++;
    if (!enabled) return;
    _emit(
      CatalogImageLoadEvent(
        url: url,
        tag: tag,
        phase: CatalogImageLoadPhase.success,
        httpStatus: httpStatus,
      ),
    );
  }

  static void logFailure({
    required String? url,
    required Object error,
    StackTrace? stackTrace,
    String tag = 'CatalogNetworkImage',
    int? httpStatus,
    String? corsHint,
  }) {
    if (url == null || url.isEmpty) return;
    failureCount++;
    if (!enabled) return;

    final message = _formatError(error, corsHint: corsHint);
    _emit(
      CatalogImageLoadEvent(
        url: url,
        tag: tag,
        phase: CatalogImageLoadPhase.failure,
        httpStatus: httpStatus,
        message: message,
        stackTrace: stackTrace,
      ),
    );
  }

  static Future<CatalogImageProbeResult> probeUrl(
    String url, {
    String tag = 'probe',
  }) async {
    final started = DateTime.now();
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      final ok = response.statusCode >= 200 && response.statusCode < 400;
      if (ok) {
        probeOkCount++;
      } else {
        probeFailCount++;
      }

      if (enabled) {
        _emit(
          CatalogImageLoadEvent(
            url: url,
            tag: tag,
            phase: ok
                ? CatalogImageLoadPhase.probeOk
                : CatalogImageLoadPhase.probeFail,
            httpStatus: response.statusCode,
            message: response.reasonPhrase,
            durationMs:
                DateTime.now().difference(started).inMilliseconds,
          ),
        );
      }

      return CatalogImageProbeResult(
        url: url,
        ok: ok,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        durationMs: DateTime.now().difference(started).inMilliseconds,
      );
    } catch (error, stackTrace) {
      probeFailCount++;
      final cors = _looksLikeCors(error);
      if (enabled) {
        logFailure(
          url: url,
          error: error,
          stackTrace: stackTrace,
          tag: tag,
          corsHint: cors ? 'Likely CORS — configure Storage bucket CORS' : null,
        );
      }
      return CatalogImageProbeResult(
        url: url,
        ok: false,
        error: error.toString(),
        isLikelyCors: cors,
        durationMs: DateTime.now().difference(started).inMilliseconds,
      );
    }
  }

  static void printSummary() {
    if (!enabled) return;
    debugPrint(
      '[CatalogImage] loads ok=$successCount fail=$failureCount '
      'rate=${(loadSuccessRate * 100).toStringAsFixed(1)}% '
      'probes ok=$probeOkCount fail=$probeFailCount',
    );
  }

  static void _emit(CatalogImageLoadEvent event) {
    _recent.add(event);
    if (_recent.length > _maxRecent) {
      _recent.removeAt(0);
    }
    debugPrint('[CatalogImage] ${event.toLogLine()}');
  }

  static String _formatError(Object error, {String? corsHint}) {
    final base = error.toString();
    if (corsHint != null) return '$base | $corsHint';
    if (_looksLikeCors(error)) {
      return '$base | Likely CORS (browser blocked cross-origin image fetch)';
    }
    if (base.contains('403') || base.toLowerCase().contains('permission')) {
      return '$base | Firebase Storage permission denied';
    }
    if (base.contains('404')) {
      return '$base | File missing or deleted in Storage';
    }
    return base;
  }

  static bool _looksLikeCors(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('cors') ||
        s.contains('cross-origin') ||
        s.contains('access-control') ||
        s.contains('networkerror');
  }
}

enum CatalogImageLoadPhase {
  attempt,
  success,
  failure,
  probeOk,
  probeFail,
}

class CatalogImageLoadEvent {
  CatalogImageLoadEvent({
    required this.url,
    required this.tag,
    required this.phase,
    this.httpStatus,
    this.message,
    this.stackTrace,
    this.durationMs,
  }) : at = DateTime.now();

  final String url;
  final String tag;
  final CatalogImageLoadPhase phase;
  final int? httpStatus;
  final String? message;
  final StackTrace? stackTrace;
  final int? durationMs;
  final DateTime at;

  String toLogLine() {
    final status = httpStatus == null ? '' : ' status=$httpStatus';
    final msg = message == null ? '' : ' err=$message';
    final ms = durationMs == null ? '' : ' ${durationMs}ms';
    return '${phase.name}$status$msg$url$ms';
  }
}

class CatalogImageProbeResult {
  const CatalogImageProbeResult({
    required this.url,
    required this.ok,
    this.statusCode,
    this.reasonPhrase,
    this.error,
    this.isLikelyCors = false,
    this.durationMs,
  });

  final String url;
  final bool ok;
  final int? statusCode;
  final String? reasonPhrase;
  final String? error;
  final bool isLikelyCors;
  final int? durationMs;
}
