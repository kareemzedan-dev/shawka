import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';

/// سجل البحث — العناوين من لوحة التحكم؛ يظهر فقط عند وجود سجل + عنوان.
class SearchRecentList extends StatelessWidget {
  const SearchRecentList({
    super.key,
    required this.searches,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
    required this.title,
    required this.clearLabel,
  });

  final List<String> searches;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;
  final String title;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty || title.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SearchTokens.pagePadding,
        SearchTokens.spaceSm,
        SearchTokens.pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: CartTypography.style(
                    fontSize: SearchTokens.sectionTitleSize,
                    fontWeight: FontWeight.w800,
                    color: SearchTokens.textPrimary,
                  ),
                ),
              ),
              if (clearLabel.trim().isNotEmpty)
                Semantics(
                  button: true,
                  label: clearLabel,
                  child: TextButton(
                    onPressed: onClearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: SearchTokens.dangerText,
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      clearLabel,
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SearchTokens.dangerText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final q in searches) ...[
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onTap(q),
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: SearchTokens.recentRowHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 20,
                          color: SearchTokens.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: SearchTokens.textPrimary,
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: q,
                          child: IconButton(
                            onPressed: () => onRemove(q),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: SearchTokens.textMuted,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
