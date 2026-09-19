import 'package:firebase_storage/firebase_storage.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';

/// Resolves fresh download URLs via Firebase Storage SDK when stored URLs are stale.
abstract final class CatalogImageStorageResolver {
  static final Map<String, String> _resolved = {};
  static final Set<String> _missing = {};

  static Future<String?> resolvePath(String objectPath) async {
    final path = objectPath.trim();
    if (path.isEmpty) return null;
    if (_missing.contains(path)) return null;

    final cached = _resolved[path];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      _resolved[path] = url;
      return url;
    } catch (_) {
      _missing.add(path);
      return null;
    }
  }

  static Future<String?> resolveFromFields({
    String? thumbnailUrl,
    String? imageUrl,
  }) async {
    for (final path in CatalogImageUrlResolver.storageObjectPaths(
      thumbnailUrl: thumbnailUrl,
      imageUrl: imageUrl,
    )) {
      final url = await resolvePath(path);
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}
