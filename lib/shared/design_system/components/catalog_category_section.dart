import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/staggered_fade_in.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/shared/design_system/components/catalog_category_card.dart';

/// Horizontal scrolling category strip with "All" tile.
class CatalogCategorySection extends StatelessWidget {
  const CatalogCategorySection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<StoreCategoryEntry> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return StaggeredFadeIn(
              index: index,
              child: CatalogCategoryCard(
                label: 'الكل',
                subtitle: 'كل المتاجر',
                imageAsset: AppAssets.categoryAll,
                isSelected: selectedCategoryId == null,
                onTap: () => onSelected(null),
                palette: palette,
              ),
            );
          }
          final entry = categories[index - 1];
          final def = entry.definition;
          return StaggeredFadeIn(
            index: index,
            child: CatalogCategoryCard(
              label: def.name,
              subtitle: '${entry.storeCount} متجر',
              imageAsset: def.imageAsset,
              imageUrl: def.imageUrl,
              imageThumbUrl: def.imageThumbUrl,
              isSelected: selectedCategoryId == def.id,
              onTap: () => onSelected(def.id),
              palette: palette,
            ),
          );
        },
      ),
    );
  }
}
