import 'dart:convert';

import 'package:matlobgo/config/branding/generated/branding_values.g.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:web/web.dart' as web;

/// Dynamic SEO — meta tags, Open Graph, Twitter Cards, JSON-LD.
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
  }) {
    final fullTitle = title.contains(WebConstants.siteName)
        ? title
        : '$title | ${WebConstants.siteName}';
    final canonical = canonicalPath == null
        ? WebConstants.canonicalOrigin
        : '${WebConstants.canonicalOrigin}$canonicalPath';
    final ogImage = imageUrl ?? '${WebConstants.canonicalOrigin}/icons/Icon-512.png';

    _setTitle(fullTitle);
    _setMeta('description', description);
    _setMeta('og:title', fullTitle, property: true);
    _setMeta('og:description', description, property: true);
    _setMeta('og:type', type, property: true);
    _setMeta('og:url', canonical, property: true);
    _setMeta('og:image', ogImage, property: true);
    _setMeta('og:locale', 'ar_EG', property: true);
    _setMeta('og:site_name', WebConstants.siteName, property: true);
    _setMeta('twitter:card', 'summary_large_image');
    _setMeta('twitter:title', fullTitle);
    _setMeta('twitter:description', description);
    _setMeta('twitter:image', ogImage);
    _setLink('canonical', canonical);

    if (jsonLd != null) {
      _setJsonLd(jsonLd);
    }
  }

  void _setTitle(String value) {
    web.document.title = value;
  }

  void _setMeta(String name, String content, {bool property = false}) {
    final selector = property
        ? 'meta[property="$name"]'
        : 'meta[name="$name"]';
    final element =
        web.document.querySelector(selector) as web.HTMLMetaElement?;
    if (element != null) {
      element.content = content;
      return;
    }
    final meta = web.document.createElement('meta') as web.HTMLMetaElement;
    if (property) {
      meta.setAttribute('property', name);
    } else {
      meta.name = name;
    }
    meta.content = content;
    web.document.head?.appendChild(meta);
  }

  void _setLink(String rel, String href) {
    final existing =
        web.document.querySelector('link[rel="$rel"]') as web.HTMLLinkElement?;
    if (existing != null) {
      existing.href = href;
      return;
    }
    final link = (web.document.createElement('link') as web.HTMLLinkElement)
      ..rel = rel
      ..href = href;
    web.document.head?.appendChild(link);
  }

  void _setJsonLd(Map<String, dynamic> data) {
    const id = 'matlobgo-json-ld';
    web.document.getElementById(id)?.remove();
    final script =
        (web.document.createElement('script') as web.HTMLScriptElement)
      ..id = id
      ..type = 'application/ld+json'
      ..text = jsonEncode(data);
    web.document.head?.appendChild(script);
  }
}
