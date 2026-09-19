import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache مشترك + prefetch متوازي لصور القوائم والرئيسية.
class CatalogImageCache {
  CatalogImageCache._();

  static final CacheManager manager = CacheManager(
    Config(
      'matlob_catalog_v3',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 180,
    ),
  );

  static const _downloadTimeout = Duration(seconds: 4);

  static final Set<String> _inflight = {};
  static final Set<String> _completed = {};
  static final Set<String> _failed = {};

  /// URLs that returned 404/missing — skip re-download until app restart.
  static bool isKnownFailed(String? url) {
    final u = url?.trim();
    return u != null && u.isNotEmpty && _failed.contains(u);
  }

  static void markFailed(String url) {
    final u = url.trim();
    if (u.isEmpty) return;
    _failed.add(u);
    _inflight.remove(u);
  }

  static void markFailedIfPermanent(String url, Object error) {
    if (_isPermanentFailure(error)) {
      markFailed(url);
    }
  }

  static Future<void> prefetch(Iterable<String?> urls) async {
    final pending = <String>[];
    for (final raw in urls) {
      final url = raw?.trim();
      if (url == null || url.isEmpty) continue;
      if (_completed.contains(url) ||
          _inflight.contains(url) ||
          _failed.contains(url)) {
        continue;
      }
      _inflight.add(url);
      pending.add(url);
    }
    if (pending.isEmpty) return;

    const batchSize = 2;
    for (var i = 0; i < pending.length; i += batchSize) {
      final batch = pending.skip(i).take(batchSize);
      await Future.wait(
        batch.map(_downloadOne),
        eagerError: false,
      );
      if (i + batchSize < pending.length) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }
  }

  static Future<FileInfo?> downloadWithTimeout(String url) async {
    if (_failed.contains(url)) return null;
    try {
      final info = await manager
          .downloadFile(url)
          .timeout(_downloadTimeout);
      _completed.add(url);
      return info;
    } on TimeoutException {
      return null;
    } catch (error) {
      if (_isPermanentFailure(error)) {
        _failed.add(url);
      }
      return null;
    } finally {
      _inflight.remove(url);
    }
  }

  static bool _isPermanentFailure(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('404') ||
        message.contains('object does not exist') ||
        message.contains('not found');
  }

  static Iterable<String> filterPrefetchable(Iterable<String> urls) {
    return urls.where(
      (url) =>
          url.isNotEmpty &&
          !_completed.contains(url) &&
          !_inflight.contains(url) &&
          !_failed.contains(url),
    );
  }

  static Future<void> _downloadOne(String url) async {
    await downloadWithTimeout(url);
  }

  static void clearMemory() {
    _inflight.clear();
    _completed.clear();
    _failed.clear();
  }
}
