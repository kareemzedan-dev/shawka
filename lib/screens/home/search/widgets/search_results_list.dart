import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';
import 'package:matlobgo/screens/home/search/widgets/search_store_card.dart';

/// قائمة نتائج البحث مع تحميل كسول + بطاقات منتجات/تصنيفات.
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.hits,
    required this.canLoadMore,
    required this.onLoadMore,
    required this.onStoreTap,
    required this.onProductTap,
    required this.onCategoryTap,
  });

  final List<SearchHit> hits;
  final bool canLoadMore;
  final VoidCallback onLoadMore;
  final ValueChanged<Store> onStoreTap;
  final void Function(Store store, Product product) onProductTap;
  final ValueChanged<StoreCategoryDef> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 &&
            canLoadMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          SearchTokens.pagePadding,
          8,
          SearchTokens.pagePadding,
          SearchTokens.space3xl,
        ),
        itemCount: hits.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final hit = hits[index];
          if (hit.isCategory && hit.category != null) {
            return _CategoryHitTile(
              category: hit.category!,
              onTap: () => onCategoryTap(hit.category!),
            );
          }
          if (hit.isProduct && hit.store != null && hit.product != null) {
            return _ProductHitTile(
              store: hit.store!,
              product: hit.product!,
              onTap: () => onProductTap(hit.store!, hit.product!),
            );
          }
          if (hit.store != null) {
            return SearchStoreCard(
              store: hit.store!,
              showPopularBadge: index < 2,
              onTap: () => onStoreTap(hit.store!),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CategoryHitTile extends StatelessWidget {
  const _CategoryHitTile({required this.category, required this.onTap});

  final StoreCategoryDef category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: SearchTokens.popularChipFill,
          child: Icon(category.icon, color: SearchTokens.accent),
        ),
        title: Text(
          category.name,
          style: CartTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: SearchTokens.textPrimary,
          ),
        ),
        subtitle: Text(
          'تصنيف',
          style: CartTypography.style(
            fontSize: 12,
            color: SearchTokens.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded),
      ),
    );
  }
}

class _ProductHitTile extends StatelessWidget {
  const _ProductHitTile({
    required this.store,
    required this.product,
    required this.onTap,
  });

  final Store store;
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: CatalogNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 128,
                    cacheHeight: 128,
                    fallback: SafeAssetImage(
                      asset: AppAssets.categoryFallback,
                      fallbackIcon: Icons.fastfood_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: SearchTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SearchTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${product.price.toStringAsFixed(0)} ج',
                style: CartTypography.style(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: SearchTokens.accentText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
