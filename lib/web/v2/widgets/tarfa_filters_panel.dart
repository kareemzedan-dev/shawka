import 'package:flutter/material.dart';
import 'package:matlobgo/web/utils/web_store_filters.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

class TarfaFiltersPanel extends StatelessWidget {
  const TarfaFiltersPanel({
    super.key,
    required this.filters,
    required this.onChanged,
    this.isGridView = true,
    this.onViewModeChanged,
  });

  final WebStoreFilterState filters;
  final ValueChanged<WebStoreFilterState> onChanged;
  final bool isGridView;
  final ValueChanged<bool>? onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _buildChips(context),
            ),
          )
        else
          Wrap(
            spacing: TarfaTokens.s8,
            runSpacing: TarfaTokens.s8,
            children: _buildChips(context),
          ),
        const SizedBox(height: TarfaTokens.s16),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterDropdown<WebStoreSort>(
                      label: 'الترتيب',
                      value: filters.sort,
                      items: const {
                        WebStoreSort.recommended: 'موصى به',
                        WebStoreSort.rating: 'التقييم',
                        WebStoreSort.delivery: 'وقت التوصيل',
                        WebStoreSort.minOrder: 'الحد الأدنى',
                      },
                      onChanged: (v) => onChanged(filters.copyWith(sort: v)),
                    ),
                    const SizedBox(width: TarfaTokens.s8),
                    _FilterDropdown<double>(
                      label: 'التقييم',
                      value: filters.minRating,
                      items: {
                        0: 'الكل',
                        4: '4+',
                        4.5: '4.5+',
                      },
                      onChanged: (v) =>
                          onChanged(filters.copyWith(minRating: v)),
                    ),
                    const SizedBox(width: TarfaTokens.s8),
                    _FilterDropdown<int?>(
                      label: 'وقت التوصيل',
                      value: filters.maxDeliveryMinutes,
                      items: const {
                        null: 'الكل',
                        30: '30 دقيقة',
                        45: '45 دقيقة',
                        60: '60 دقيقة',
                      },
                      onChanged: (v) =>
                          onChanged(filters.copyWith(maxDeliveryMinutes: v)),
                    ),
                    const SizedBox(width: TarfaTokens.s8),
                    _FilterDropdown<WebPriceFilter>(
                      label: 'السعر',
                      value: filters.priceFilter,
                      items: const {
                        WebPriceFilter.any: 'الكل',
                        WebPriceFilter.lowDelivery: 'توصيل رخيص',
                        WebPriceFilter.freeDeliveryEligible: 'توصيل مجاني',
                      },
                      onChanged: (v) =>
                          onChanged(filters.copyWith(priceFilter: v)),
                    ),
                  ],
                ),
              ),
            ),
            if (onViewModeChanged != null) ...[
              const SizedBox(width: TarfaTokens.s8),
              Container(
                decoration: BoxDecoration(
                  color: TarfaTokens.surface,
                  borderRadius: TarfaTokens.borderRadius,
                  boxShadow: TarfaTokens.shadowSm,
                ),
                child: Row(
                  children: [
                    _ViewToggle(
                      icon: Icons.grid_view_rounded,
                      selected: isGridView,
                      onTap: () => onViewModeChanged!(true),
                    ),
                    _ViewToggle(
                      icon: Icons.view_list_rounded,
                      selected: !isGridView,
                      onTap: () => onViewModeChanged!(false),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  List<Widget> _buildChips(BuildContext context) {
    return [
      _ToggleChip(
        label: 'عروض',
        selected: filters.offersOnly,
        onTap: () => onChanged(
          filters.copyWith(offersOnly: !filters.offersOnly),
        ),
      ),
      _ToggleChip(
        label: 'مفتوح الآن',
        selected: true,
        onTap: () {},
      ),
      _ToggleChip(
        label: 'توصيل سريع',
        selected: filters.maxDeliveryMinutes == 30,
        onTap: () => onChanged(
          filters.copyWith(
            maxDeliveryMinutes:
                filters.maxDeliveryMinutes == 30 ? null : 30,
          ),
        ),
      ),
      _ToggleChip(
        label: 'تقييم عالي',
        selected: filters.minRating >= 4.5,
        onTap: () => onChanged(
          filters.copyWith(minRating: filters.minRating >= 4.5 ? 0 : 4.5),
        ),
      ),
    ];
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: TarfaTokens.s8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: TarfaTokens.secondary.withValues(alpha: 0.12),
        checkmarkColor: TarfaTokens.secondary,
        labelStyle: TarfaTokens.labelMedium(context).copyWith(
          color: selected ? TarfaTokens.secondary : TarfaTokens.textSecondary,
        ),
        backgroundColor: TarfaTokens.surface,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: TarfaTokens.borderRadius,
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TarfaTokens.s12),
      decoration: BoxDecoration(
        color: TarfaTokens.surface,
        borderRadius: TarfaTokens.borderRadius,
        boxShadow: TarfaTokens.shadowSm,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label, style: TarfaTokens.labelMedium(context)),
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: TarfaTokens.labelMedium(context)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? TarfaTokens.secondary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: TarfaTokens.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: TarfaTokens.borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(TarfaTokens.s12),
          child: Icon(
            icon,
            size: 20,
            color: selected ? TarfaTokens.secondary : TarfaTokens.textMuted,
          ),
        ),
      ),
    );
  }
}
