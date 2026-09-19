import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';

Future<SearchAdvancedFilters?> showSearchFilterSheet(
  BuildContext context, {
  required SearchAdvancedFilters current,
}) {
  return showModalBottomSheet<SearchAdvancedFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _SearchFilterSheet(initial: current),
  );
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({required this.initial});

  final SearchAdvancedFilters initial;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late SearchAdvancedFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SearchTokens.chipIdleBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تصفية النتائج',
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: SearchTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _filters.openOnly,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(openOnly: v)),
              title: Text(
                'المفتوح فقط',
                style: CartTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              activeThumbColor: SearchTokens.accent,
            ),
            SwitchListTile.adaptive(
              value: _filters.freeDeliveryOnly,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(freeDeliveryOnly: v),
              ),
              title: Text(
                'توصيل مجاني',
                style: CartTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              activeThumbColor: SearchTokens.accent,
            ),
            SwitchListTile.adaptive(
              value: _filters.offersOnly,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(offersOnly: v)),
              title: Text(
                'عروض فقط',
                style: CartTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              activeThumbColor: SearchTokens.accent,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const SearchAdvancedFilters(),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('إعادة ضبط'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _filters),
                    style: FilledButton.styleFrom(
                      backgroundColor: SearchTokens.accent,
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
