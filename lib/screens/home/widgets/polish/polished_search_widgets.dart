import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/ui_polish_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/cms_text_service.dart';

const _searchSuggestionIcons = [
  Icons.local_pizza_rounded,
  Icons.lunch_dining_rounded,
  Icons.rice_bowl_rounded,
  Icons.kebab_dining_rounded,
  Icons.cake_rounded,
];

class PolishedSearchHeader extends StatelessWidget {
  const PolishedSearchHeader({
    super.key,
    required this.topPadding,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onBack,
    this.onFilterTap,
  });

  final double topPadding;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.inkElevated, UiPolishTokens.navy, AppColors.black],
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'البحث',
                  style: UiPolishTokens.titleLg(
                    Colors.white,
                  ).copyWith(fontSize: 22),
                ),
              ),
              if (onFilterTap != null)
                _GlassIconButton(icon: Icons.tune_rounded, onTap: onFilterTap!),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
              boxShadow: UiPolishTokens.cardShadow,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.textSecondary,
                      ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.mic_rounded,
                        color: AppColors.textHint.withValues(alpha: 0.8),
                      ),
                      tooltip: 'بحث صوتي قريباً',
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UiPolishTokens.glass().color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class SearchSuggestionChips extends StatelessWidget {
  const SearchSuggestionChips({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final suggestions = CmsTextService.instance.searchSuggestions();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: UiPolishTokens.spaceMd),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final label = suggestions[i];
          final icon =
              _searchSuggestionIcons[i % _searchSuggestionIcons.length];
          return GestureDetector(
            onTap: () => onTap(label),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: UiPolishTokens.cardShadow,
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: UiPolishTokens.caption(AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PolishedSearchResultTile extends StatelessWidget {
  const PolishedSearchResultTile({
    super.key,
    required this.store,
    required this.onTap,
    this.rank,
  });

  final Store store;
  final VoidCallback? onTap;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final delivery = store.deliveryFee == 0
        ? 'توصيل مجاني'
        : '${store.deliveryFee.toInt()} ج';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
            border: Border.all(color: const Color(0xFFE8ECF3)),
            boxShadow: UiPolishTokens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: CatalogNetworkImage(
                      imageUrl: store.displayHeroImageUrl,
                      thumbnailUrl: store.displayHeroThumbUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 144,
                      cacheHeight: 144,
                      fallback: SafeAssetImage(
                        asset: AppAssets.categoryFallback,
                        fallbackIcon: store.categoryIcon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (rank != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$rank',
                                style: UiPolishTokens.caption(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              store.name,
                              style: UiPolishTokens.titleMd(
                                store.isOpen
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ).copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.categoryLabel,
                        style: UiPolishTokens.caption(AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (store.rating > 0 || store.reviewCount > 0)
                            _MetaChip(
                              icon: Icons.star_rounded,
                              label: store.rating > 0
                                  ? store.rating.toStringAsFixed(1)
                                  : '${store.reviewCount} تقييم',
                              color: AppColors.primary,
                            ),
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: '${store.deliveryMinutes} د',
                          ),
                          _MetaChip(
                            icon: Icons.delivery_dining_rounded,
                            label: delivery,
                          ),
                          if (!store.isOpen)
                            _MetaChip(
                              icon: Icons.lock_clock_rounded,
                              label: 'مغلق حالياً',
                              color: AppColors.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textHint.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: UiPolishTokens.caption(c)),
        ],
      ),
    );
  }
}

class PolishSectionHeader extends StatelessWidget {
  const PolishSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        UiPolishTokens.spaceMd,
        UiPolishTokens.spaceMd,
        UiPolishTokens.spaceMd,
        UiPolishTokens.spaceSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: UiPolishTokens.titleMd(AppColors.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: UiPolishTokens.caption(AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class SearchPromoBanner extends StatelessWidget {
  const SearchPromoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        UiPolishTokens.spaceMd,
        0,
        UiPolishTokens.spaceMd,
        UiPolishTokens.spaceMd,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiPolishTokens.radiusMd),
              gradient: AppColors.primaryGradient,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: AppColors.textOnPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'عروض حصرية على موردينك المفضلين',
                    style: GoogleFonts.cairo(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'تصفح',
                  style: GoogleFonts.cairo(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
