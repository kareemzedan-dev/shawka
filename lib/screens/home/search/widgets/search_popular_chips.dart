import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';

/// الكلمات الأكثر بحثاً — من لوحة التحكم فقط.
class SearchPopularChips extends StatelessWidget {
  const SearchPopularChips({
    super.key,
    required this.terms,
    required this.onTap,
    required this.title,
  });

  final List<PopularSearchTerm> terms;
  final ValueChanged<String> onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (terms.isEmpty || title.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SearchTokens.pagePadding,
        SearchTokens.spaceMd,
        SearchTokens.pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: CartTypography.style(
              fontSize: SearchTokens.sectionTitleSize,
              fontWeight: FontWeight.w800,
              color: SearchTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in terms)
                Semantics(
                  button: true,
                  label: term.label,
                  child: Material(
                    color: SearchTokens.popularChipFill,
                    borderRadius: BorderRadius.circular(SearchTokens.radiusPill),
                    child: InkWell(
                      onTap: () => onTap(term.label),
                      borderRadius:
                          BorderRadius.circular(SearchTokens.radiusPill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          term.label,
                          style: CartTypography.style(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: term.hot
                                ? SearchTokens.popularHot
                                : SearchTokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
