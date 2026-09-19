import 'package:firebase_core/firebase_core.dart';

/// Normalizes catalog image URLs from Firestore / Storage for browser and app use.
abstract final class CatalogImageUrlResolver {
  /// Shawka Firebase Storage bucket (current project).
  static const defaultBucket = 'shawka-689fa.firebasestorage.app';

  /// Same-project legacy host form.
  static const _legacyBucket = 'shawka-689fa.appspot.com';

  /// Pre-migration Matlobgo buckets — rewritten to [defaultBucket].
  static const _retiredBuckets = <String>[
    'matlobgo.firebasestorage.app',
    'matlobgo.appspot.com',
  ];

  static const _firebaseStorageHost = 'firebasestorage.googleapis.com';

  /// Synchronous normalization — converts `gs://`, fixes bucket names, encoding.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('gs://')) {
      return _gsToHttps(trimmed);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _fixHttpsEncoding(_rewriteRetiredBucket(trimmed));
    }

    // Relative storage path (e.g. stores/id/logo.jpg)
    if (!trimmed.contains('://') && trimmed.contains('/')) {
      return _publicDownloadUrl(
        bucket: _activeBucket(),
        objectPath: trimmed,
      );
    }

    return null;
  }

  /// Ordered load candidates: thumb → full (or reversed), then safer alternates.
  ///
  /// Priority:
  /// 1) Original Firestore HTTPS URL (token + current bucket)
  /// 2) Normalized / encoding-fixed variants of the same bucket
  /// 3) Token-free public alt=media (same bucket)
  /// 4) Legacy `.appspot.com` bucket last
  static List<String> candidateUrls({
    String? thumbnailUrl,
    String? imageUrl,
    bool useFullResolution = false,
  }) {
    final primary = <String>[];
    final legacy = <String>[];

    void addRaw(String? raw) {
      if (raw == null) return;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;

      // Keep the Firestore URL first — token + bucket must not be rewritten.
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final fixed = _fixHttpsEncoding(_rewriteRetiredBucket(trimmed));
        if (fixed.contains('/b/$_legacyBucket/')) {
          _addUnique(legacy, fixed);
          final modern = alternateBucketUrl(fixed);
          if (modern != null) _addUnique(primary, modern);
        } else {
          _addUnique(primary, fixed);
        }
      }

      final normalized = normalize(trimmed);
      if (normalized == null || normalized.isEmpty) return;

      if (normalized.contains('/b/$_legacyBucket/')) {
        _addUnique(legacy, normalized);
        final modern = alternateBucketUrl(normalized);
        if (modern != null) _addUnique(primary, modern);
      } else {
        _addUnique(primary, normalized);
      }

      final public = publicAltMediaUrl(normalized);
      if (public != null) {
        if (public.contains('/b/$_legacyBucket/')) {
          _addUnique(legacy, public);
        } else {
          _addUnique(primary, public);
        }
      }

      if (trimmed.startsWith('http')) {
        final publicRaw = publicAltMediaUrl(
          _fixHttpsEncoding(_rewriteRetiredBucket(trimmed)),
        );
        if (publicRaw != null) {
          if (publicRaw.contains('/b/$_legacyBucket/')) {
            _addUnique(legacy, publicRaw);
          } else {
            _addUnique(primary, publicRaw);
          }
        }
      }

      // Legacy alternate only after modern candidates for this field.
      final alt = alternateBucketUrl(normalized);
      if (alt != null && alt.contains('/b/$_legacyBucket/')) {
        _addUnique(legacy, alt);
      }
    }

    if (useFullResolution) {
      addRaw(imageUrl);
      addRaw(thumbnailUrl);
    } else {
      addRaw(thumbnailUrl);
      addRaw(imageUrl);
    }

    return [...primary, ...legacy];
  }

  /// Firebase Storage object path from a download URL (e.g. `stores/id/cover.jpg`).
  static String? extractStorageObjectPath(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('gs://')) {
      return extractGsPath(trimmed);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host != _firebaseStorageHost) return null;

    final marker = '/o/';
    final idx = uri.path.indexOf(marker);
    if (idx < 0) return null;

    var encoded = uri.path.substring(idx + marker.length);
    if (encoded.isEmpty) return null;

    try {
      return Uri.decodeComponent(encoded);
    } catch (_) {
      return null;
    }
  }

  /// Collect unique Storage paths from image fields for SDK fallback.
  static List<String> storageObjectPaths({
    String? thumbnailUrl,
    String? imageUrl,
  }) {
    final paths = <String>[];
    void add(String? raw) {
      final path = extractStorageObjectPath(raw);
      if (path != null && path.isNotEmpty && !paths.contains(path)) {
        paths.add(path);
      }
    }

    add(thumbnailUrl);
    add(imageUrl);
    return paths;
  }

  /// Swap Shawka `.appspot.com` ↔ `.firebasestorage.app` in download URLs.
  static String? alternateBucketUrl(String url) {
    if (!url.contains(_firebaseStorageHost)) return null;
    if (url.contains('/b/$_legacyBucket/')) {
      return url.replaceFirst('/b/$_legacyBucket/', '/b/$defaultBucket/');
    }
    if (url.contains('/b/$defaultBucket/')) {
      return url.replaceFirst('/b/$defaultBucket/', '/b/$_legacyBucket/');
    }
    return null;
  }

  /// Strip `token` query param — works for publicly readable Storage objects.
  static String? publicAltMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != _firebaseStorageHost) return null;
    if (!uri.path.contains('/o/')) return null;

    final base = uri.replace(queryParameters: {'alt': 'media'});
    final withoutToken = Uri(
      scheme: base.scheme,
      host: base.host,
      path: base.path,
      queryParameters: const {'alt': 'media'},
    );
    final stripped = withoutToken.toString();
    if (stripped == url) return null;
    return stripped;
  }

  /// Extract `gs://` path for migration logging.
  static String? extractGsPath(String? raw) {
    if (raw == null || !raw.trim().startsWith('gs://')) return null;
    final without = raw.trim().substring(5);
    final slash = without.indexOf('/');
    if (slash <= 0 || slash >= without.length - 1) return null;
    return without.substring(slash + 1);
  }

  static String _activeBucket() {
    try {
      return Firebase.app().options.storageBucket ?? defaultBucket;
    } catch (_) {
      return defaultBucket;
    }
  }

  static String? _gsToHttps(String gsUrl) {
    final without = gsUrl.substring(5);
    final slash = without.indexOf('/');
    if (slash <= 0 || slash >= without.length - 1) return null;

    var bucket = without.substring(0, slash);
    if (bucket == _legacyBucket || _retiredBuckets.contains(bucket)) {
      bucket = defaultBucket;
    }
    final objectPath = without.substring(slash + 1);
    return _publicDownloadUrl(bucket: bucket, objectPath: objectPath);
  }

  /// Rewrite retired Matlobgo bucket hosts to Shawka.
  static String _rewriteRetiredBucket(String url) {
    var out = url;
    for (final retired in _retiredBuckets) {
      if (out.contains('/b/$retired/')) {
        out = out.replaceFirst('/b/$retired/', '/b/$defaultBucket/');
      }
      if (out.startsWith('gs://$retired/')) {
        out = out.replaceFirst('gs://$retired/', 'gs://$defaultBucket/');
      }
    }
    return out;
  }

  static String _publicDownloadUrl({
    required String bucket,
    required String objectPath,
  }) {
    final encoded = objectPath
        .split('/')
        .map((segment) => Uri.encodeComponent(segment))
        .join('%2F');
    return 'https://$_firebaseStorageHost/v0/b/$bucket/o/$encoded?alt=media';
  }

  /// Fix double-encoding only — never rewrite bucket (breaks download tokens).
  static String _fixHttpsEncoding(String url) {
    var fixed = url.trim();
    if (fixed.contains('%252F') || fixed.contains('%2525')) {
      try {
        fixed = Uri.decodeFull(fixed);
      } catch (_) {}
    }
    return fixed;
  }

  static void _addUnique(List<String> list, String url) {
    if (!list.contains(url)) list.add(url);
  }

  /// Preserve Firestore download URLs as-is; only normalize gs:// and relative paths.
  static String? storedValue(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('gs://')) {
      return normalize(trimmed);
    }

    if (!trimmed.contains('://') && trimmed.contains('/')) {
      return normalize(trimmed);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _fixHttpsEncoding(_rewriteRetiredBucket(trimmed));
    }

    return null;
  }
}

/// Preserve Firestore download URLs as-is; only normalize gs:// and relative paths.
String? normalizeStoredImageUrl(String? raw) =>
    CatalogImageUrlResolver.storedValue(raw);
