import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/repositories/product_repository.dart';

/// صورة منتج السلة — من الـ CartItem أو من الكتالوج (قراءة فقط).
class CartItemThumbnail extends StatelessWidget {
  const CartItemThumbnail({
    super.key,
    required this.item,
    required this.palette,
    this.size = 72,
  });

  final CartItem item;
  final AppPalette palette;
  final double size;

  bool get _hasStoredImage =>
      (item.imageThumbUrl?.trim().isNotEmpty ?? false) ||
      (item.imageUrl?.trim().isNotEmpty ?? false);

  Product? _matchProduct(List<Product> products) {
    for (final p in products) {
      final base = '${item.storeId}_${p.id}';
      if (item.id == base || item.id.startsWith('${base}_')) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final border = Border.all(
      color: palette.border,
      width: 1,
    );

    Widget imageBox({String? url, String? thumb}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: border,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: CatalogNetworkImage(
            imageUrl: url,
            thumbnailUrl: thumb,
            cacheWidth: (size * 2.5).round(),
            cacheHeight: (size * 2.5).round(),
            fallback: _ThumbPlaceholder(palette: palette),
          ),
        ),
      );
    }

    if (_hasStoredImage) {
      return imageBox(url: item.imageUrl, thumb: item.imageThumbUrl);
    }

    return StreamBuilder<List<Product>>(
      stream: ProductRepository().watchProducts(item.storeId, activeOnly: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _ThumbShimmer(palette: palette, size: size);
        }
        final product = _matchProduct(snapshot.data ?? []);
        if (product != null) {
          return imageBox(
            url: product.imageUrl,
            thumb: product.imageThumbUrl,
          );
        }
        return imageBox(url: item.imageUrl, thumb: item.imageThumbUrl);
      },
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          color: palette.textHint.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }
}

class _ThumbShimmer extends StatelessWidget {
  const _ThumbShimmer({required this.palette, required this.size});

  final AppPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
