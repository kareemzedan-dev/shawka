import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';

enum HomeQuickFilter {
  all,
  offers,
  freeDelivery,
}

extension HomeQuickFilterX on HomeQuickFilter {
  String get label => switch (this) {
        HomeQuickFilter.all => 'الكل',
        HomeQuickFilter.offers => 'عروض',
        HomeQuickFilter.freeDelivery => 'توصيل مجاني',
      };

  IconData get icon => switch (this) {
        HomeQuickFilter.all => Icons.grid_view_rounded,
        HomeQuickFilter.offers => Icons.local_offer_outlined,
        HomeQuickFilter.freeDelivery => Icons.delivery_dining_outlined,
      };

  IconData get activeIcon => switch (this) {
        HomeQuickFilter.all => Icons.grid_view_rounded,
        HomeQuickFilter.offers => Icons.local_offer_rounded,
        HomeQuickFilter.freeDelivery => Icons.delivery_dining_rounded,
      };
}

class HomeQuickFilters extends StatelessWidget {
  const HomeQuickFilters({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HomeQuickFilter selected;
  final ValueChanged<HomeQuickFilter> onSelected;

  static const _filters = HomeQuickFilter.values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selected == filter;
          return _QuickFilterChip(
            icon: isSelected ? filter.activeIcon : filter.icon,
            label: filter.label,
            isSelected: isSelected,
            onTap: () {
              if (filter == HomeQuickFilter.all) {
                onSelected(HomeQuickFilter.all);
                return;
              }
              onSelected(isSelected ? HomeQuickFilter.all : filter);
            },
          );
        },
      ),
    );
  }
}

class _QuickFilterChip extends StatefulWidget {
  const _QuickFilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_QuickFilterChip> createState() => _QuickFilterChipState();
}

class _QuickFilterChipState extends State<_QuickFilterChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: HomeTheme.animPress,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: HomeTheme.animNormal,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? AppColors.primaryGradient : null,
            color: widget.isSelected
                ? null
                : AppColors.white.withValues(alpha: 0.08),
            borderRadius: HomeTheme.borderMd,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primaryLight.withValues(alpha: 0.5)
                  : AppColors.white.withValues(alpha: 0.14),
              width: widget.isSelected ? 1.2 : 1,
            ),
            boxShadow: widget.isSelected ? HomeTheme.softShadowChip : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: HomeTheme.animNormal,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HomeTheme.radiusSm - 4),
                ),
                child: Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isSelected
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: HomeTheme.chipLabel.copyWith(
                  fontSize: 12.5,
                  color: widget.isSelected
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.9),
                  fontWeight:
                      widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick-filter chips for the home body (light background) — matches v2 mockup.
class MatlobHomeFilterChips extends StatelessWidget {
  const MatlobHomeFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HomeQuickFilter selected;
  final ValueChanged<HomeQuickFilter> onSelected;

  static const _visible = [
    HomeQuickFilter.all,
    HomeQuickFilter.offers,
    HomeQuickFilter.freeDelivery,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _visible.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _visible[index];
          final isSelected = selected == filter;
          return GestureDetector(
            onTap: () {
              if (filter == HomeQuickFilter.all) {
                onSelected(HomeQuickFilter.all);
              } else {
                onSelected(isSelected ? HomeQuickFilter.all : filter);
              }
            },
            child: AnimatedContainer(
              duration: HomeTheme.animNormal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE8EAED),
                ),
                boxShadow: isSelected
                    ? HomeTheme.softShadowChip
                    : [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? filter.activeIcon : filter.icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.label,
                    style: HomeTheme.chipLabel.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
