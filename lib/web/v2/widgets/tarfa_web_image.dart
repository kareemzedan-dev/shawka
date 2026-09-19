import 'package:flutter/material.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

/// Image roles used across Shawka Web — keeps fit / ratio / fallback consistent.
enum TarfaImageKind {
  banner,
  storeCover,
  storeLogo,
  product,
  category,
  promo,
}

/// Unified catalog image for the web storefront.
///
/// Always reserves space (no layout shift), shows a shimmer while loading,
/// and a branded fallback when every URL candidate fails.
class TarfaWebImage extends StatelessWidget {
  const TarfaWebImage({
    super.key,
    required this.kind,
    this.imageUrl,
    this.thumbnailUrl,
    this.fit,
    this.aspectRatio,
    this.fill = false,
    this.borderRadius,
    this.width,
    this.height,
    this.useFullResolution = false,
    this.fallbackIcon,
    this.fallback,
    this.debugTag,
  });

  final TarfaImageKind kind;
  final String? imageUrl;
  final String? thumbnailUrl;
  final BoxFit? fit;
  final double? aspectRatio;

  /// When true, fills the parent (Stack / fixed height) without AspectRatio.
  final bool fill;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final bool useFullResolution;
  final IconData? fallbackIcon;
  final Widget? fallback;
  final String? debugTag;

  BoxFit get _fit => fit ?? BoxFit.cover;

  double? get _ratio {
    if (fill || width != null || height != null) return null;
    return aspectRatio ??
        switch (kind) {
          TarfaImageKind.banner || TarfaImageKind.promo => 21 / 9,
          TarfaImageKind.storeCover => 16 / 10,
          TarfaImageKind.product => 4 / 3,
          TarfaImageKind.category => 1,
          TarfaImageKind.storeLogo => 1,
        };
  }

  IconData get _icon => fallbackIcon ?? switch (kind) {
        TarfaImageKind.banner || TarfaImageKind.promo => Icons.local_offer_rounded,
        TarfaImageKind.storeCover => Icons.storefront_rounded,
        TarfaImageKind.storeLogo => Icons.store_rounded,
        TarfaImageKind.product => Icons.fastfood_rounded,
        TarfaImageKind.category => Icons.category_rounded,
      };

  Widget _buildFallback() {
    if (fallback != null) return fallback!;
    return ColoredBox(
      color: TarfaTokens.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          _icon,
          size: kind == TarfaImageKind.storeLogo ? 28 : 40,
          color: TarfaTokens.textMuted.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const ColoredBox(color: Color(0xFFE2E8F0));
  }

  @override
  Widget build(BuildContext context) {
    final image = CatalogNetworkImage(
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      fit: _fit,
      borderRadius: borderRadius,
      useFullResolution: useFullResolution ||
          kind == TarfaImageKind.banner ||
          kind == TarfaImageKind.promo ||
          kind == TarfaImageKind.storeCover,
      placeholder: _buildPlaceholder(),
      fallback: _buildFallback(),
      debugTag: debugTag ?? 'ShawkaWebImage.${kind.name}',
    );

    Widget child = image;
    final ratio = _ratio;
    if (fill) {
      child = SizedBox.expand(child: image);
    } else if (ratio != null) {
      child = AspectRatio(aspectRatio: ratio, child: image);
    } else if (width != null || height != null) {
      child = SizedBox(width: width, height: height, child: image);
    }

    return child;
  }
}
