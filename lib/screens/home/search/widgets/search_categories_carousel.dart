import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/store_category_def.dart';

/// دوّارة تصنيفات — من لوحة التحكم (`store_categories`) فقط، بدون قيم ثابتة.
class SearchCategoriesCarousel extends StatelessWidget {
  const SearchCategoriesCarousel({
    super.key,
    required this.categories,
    required this.onTapCategory,
  });

  final List<StoreCategoryDef> categories;
  final ValueChanged<StoreCategoryDef> onTapCategory;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final items = categories.take(12).toList();

    return SizedBox(
      height: SearchTokens.categoryRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SearchTokens.pagePadding),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = items[i];
          return Semantics(
            button: true,
            label: cat.name,
            child: GestureDetector(
              onTap: () => onTapCategory(cat),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Container(
                      width: SearchTokens.categoryCircle,
                      height: SearchTokens.categoryCircle,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: SearchTokens.chipIdleBorder),
                        boxShadow: SearchTokens.cardShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CatalogNetworkImage(
                        imageUrl: cat.imageUrl,
                        thumbnailUrl: cat.imageThumbUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 112,
                        cacheHeight: 112,
                        fallback: Icon(
                          cat.icon,
                          color: SearchTokens.accent,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: CartTypography.style(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: SearchTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
