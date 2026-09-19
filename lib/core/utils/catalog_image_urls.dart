import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';

/// Display URL for list tiles — prefers thumbnail, both normalized.
String? catalogListImageUrl({String? thumbnailUrl, String? imageUrl}) {
  final candidates = CatalogImageUrlResolver.candidateUrls(
    thumbnailUrl: thumbnailUrl,
    imageUrl: imageUrl,
  );
  return candidates.isEmpty ? null : candidates.first;
}

/// All load candidates for progressive fallback (thumb → full → bucket alt → public).
List<String> catalogImageCandidateUrls({
  String? thumbnailUrl,
  String? imageUrl,
  bool useFullResolution = false,
}) {
  return CatalogImageUrlResolver.candidateUrls(
    thumbnailUrl: thumbnailUrl,
    imageUrl: imageUrl,
    useFullResolution: useFullResolution,
  );
}
