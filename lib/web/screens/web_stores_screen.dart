import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/utils/web_store_filters.dart';
import 'package:matlobgo/web/widgets/web_premium_hero.dart';
import 'package:matlobgo/web/widgets/web_store_row.dart';

class WebStoresScreen extends StatefulWidget {
  const WebStoresScreen({super.key, required this.govId});

  final String govId;

  @override
  State<WebStoresScreen> createState() => _WebStoresScreenState();
}

class _WebStoresScreenState extends State<WebStoresScreen> {
  final _catalog = CatalogService();
  final _searchController = TextEditingController();
  WebStoreFilterState _filters = const WebStoreFilterState();

  @override
  void initState() {
    super.initState();
    WebGovernorateService.instance.setGovernorateById(widget.govId);
    WebSeoService.instance.apply(
      title: 'جميع الموردين — ${WebGovernorateService.instance.governorateName}',
      description:
          'تصفّح وفلتر ورتّب الموردين في ${WebGovernorateService.instance.governorateName}.',
      canonicalPath: WebConstants.storesPath(widget.govId),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final govName = WebGovernorateService.instance.governorateName;

    return PremiumBackground.body(
      context,
      CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WebPremiumHero(
              compact: true,
              onSearchSubmit: (q) => context.push(
                '/g/${widget.govId}/search?q=${Uri.encodeComponent(q)}',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _filters = _filters.copyWith(query: v)),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مورد...',
                  hintStyle: GoogleFonts.cairo(),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _FilterChips(
            filters: _filters,
            onChanged: (f) => setState(() => _filters = f),
          )),
          StreamBuilder<List<StoreCategoryDef>>(
            stream: _catalog.watchCategories(govName),
            builder: (context, _) {
              return StreamBuilder<List<Store>>(
                stream: _catalog.watchStores(governorate: govName),
                builder: (context, snap) {
                  final filtered =
                      WebStoreFilters.apply(snap.data ?? [], _filters);
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'لا يوجد موردون مطابقون',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: WebStoreGrid(stores: filtered),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filters, required this.onChanged});

  final WebStoreFilterState filters;
  final ValueChanged<WebStoreFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _chip(
            'الأعلى تقييماً',
            filters.sort == WebStoreSort.rating,
            () => onChanged(filters.copyWith(sort: WebStoreSort.rating)),
          ),
          _chip(
            'الأسرع توصيلاً',
            filters.sort == WebStoreSort.delivery,
            () => onChanged(filters.copyWith(sort: WebStoreSort.delivery)),
          ),
          _chip(
            'عروض فقط',
            filters.offersOnly,
            () => onChanged(
              filters.copyWith(offersOnly: !filters.offersOnly),
            ),
          ),
          _chip(
            'تقييم +4',
            filters.minRating >= 4,
            () => onChanged(
              filters.copyWith(
                minRating: filters.minRating >= 4 ? 0 : 4,
              ),
            ),
          ),
          _chip(
            'توصيل ≤ 35 د',
            filters.maxDeliveryMinutes == 35,
            () => onChanged(
              filters.copyWith(
                maxDeliveryMinutes:
                    filters.maxDeliveryMinutes == 35 ? null : 35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}
