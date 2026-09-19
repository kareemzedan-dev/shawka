import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/models/store_category_def.dart';

/// شرائح فلتر التصنيف: الكل + تصنيفات Firestore.
class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.allLabel,
  });

  final List<StoreCategoryDef> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    final showAll = allLabel.trim().isNotEmpty;
    if (!showAll && categories.isEmpty) return const SizedBox.shrink();

    final count = categories.length + (showAll ? 1 : 0);
    return SizedBox(
      height: SearchTokens.filterChipHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: SearchTokens.pagePadding,
          vertical: 4,
        ),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String? catId;
          final String label;
          if (showAll && index == 0) {
            catId = null;
            label = allLabel.trim();
          } else {
            final catIndex = showAll ? index - 1 : index;
            catId = categories[catIndex].id;
            label = categories[catIndex].name;
          }
          final selected = selectedCategoryId == catId;
          return Semantics(
            button: true,
            selected: selected,
            label: label,
            child: Material(
              color: selected ? SearchTokens.accent : SearchTokens.chipIdleFill,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSelected(catId),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? SearchTokens.accent
                          : SearchTokens.chipIdleBorder,
                    ),
                  ),
                  child: Text(
                    label,
                    style: CartTypography.style(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.textOnPrimary
                          : SearchTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
