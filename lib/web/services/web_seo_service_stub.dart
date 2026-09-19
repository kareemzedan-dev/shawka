import 'package:matlobgo/config/branding/generated/branding_values.g.dart';

/// SEO stub — mobile/desktop builds.
class WebSeoService {
  WebSeoService._();
  static final WebSeoService instance = WebSeoService._();

  void apply({
    required String title,
    String description = BrandingValues.tagline,
    String? canonicalPath,
    String? imageUrl,
    String type = 'website',
    Map<String, dynamic>? jsonLd,
  }) {}
}
