import 'package:flutter/material.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/shared/design_system/components/catalog_store_card.dart';

export 'package:matlobgo/shared/design_system/components/catalog_store_card.dart'
    show CatalogStoreCard, CatalogStoreCardVariant, CatalogStoreCardSkeleton;

typedef WebPremiumStoreCardSkeleton = CatalogStoreCardSkeleton;

enum WebPremiumCardSize { grid, featured, horizontal }

CatalogStoreCardVariant _mapSize(WebPremiumCardSize size) {
  return switch (size) {
    WebPremiumCardSize.grid => CatalogStoreCardVariant.grid,
    WebPremiumCardSize.featured => CatalogStoreCardVariant.featured,
    WebPremiumCardSize.horizontal => CatalogStoreCardVariant.horizontal,
  };
}

/// Thin adapter — delegates to [CatalogStoreCard].
class WebPremiumStoreCard extends StatelessWidget {
  const WebPremiumStoreCard({
    super.key,
    required this.store,
    this.onTap,
    this.size = WebPremiumCardSize.grid,
    this.width,
  });

  final Store store;
  final VoidCallback? onTap;
  final WebPremiumCardSize size;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return CatalogStoreCard(
      store: store,
      onTap: onTap,
      variant: _mapSize(size),
      width: width,
    );
  }
}
