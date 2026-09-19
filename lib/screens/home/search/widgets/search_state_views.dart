import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';

class SearchSkeletonList extends StatelessWidget {
  const SearchSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(SearchTokens.pagePadding),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SearchTokens.cardRadius),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: SearchTokens.popularChipFill,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SearchTokens.cardRadius),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: SearchTokens.popularChipFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 140,
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: SearchTokens.popularChipFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchOfflineBanner extends StatelessWidget {
  const SearchOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        SearchTokens.pagePadding,
        8,
        SearchTokens.pagePadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'أنت غير متصل — تحقق من الشبكة ثم أعد المحاولة',
              style: CartTypography.style(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchErrorView extends StatelessWidget {
  const SearchErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SearchTokens.space3xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: SearchTokens.dangerText,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذّر تحميل نتائج البحث',
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: SearchTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: SearchTokens.accent,
                minimumSize: const Size(140, 48),
              ),
              child: Text(
                'إعادة المحاولة',
                style: CartTypography.style(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchEmptyView extends StatelessWidget {
  const SearchEmptyView({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.preset(
      AppEmptyKind.searchNoResults,
      onAction: onClear,
    );
  }
}
