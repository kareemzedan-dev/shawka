import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/utils/web_store_filters.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_filters_panel.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_search_bar.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_section_header.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_skeleton.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_store_card.dart';

class TarfaStoresScreen extends StatefulWidget {
  const TarfaStoresScreen({super.key, required this.govId});

  final String govId;

  @override
  State<TarfaStoresScreen> createState() => _TarfaStoresScreenState();
}

class _TarfaStoresScreenState extends State<TarfaStoresScreen> {
  final _catalog = CatalogService();
  final _searchController = TextEditingController();
  WebStoreFilterState _filters = const WebStoreFilterState();
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    WebGovernorateService.instance.setGovernorateById(widget.govId);
    WebSeoService.instance.apply(
      title: 'جميع المتاجر — ${WebGovernorateService.instance.governorateName}',
      canonicalPath: WebConstants.storesPath(widget.govId),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openStore(Store store) {
    if (!store.isActive) return;
    WebConversionService.instance.recordStoreVisit(store.id);
    context.push(WebConstants.storePath(store.id));
  }

  @override
  Widget build(BuildContext context) {
    final govName = WebGovernorateService.instance.governorateName;
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;
    final padding = isMobile ? TarfaTokens.s16 : TarfaTokens.s40;
    final crossAxisCount = isMobile ? 1 : 3;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, TarfaTokens.s24, padding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TarfaSectionHeader(
                  title: 'جميع المتاجر',
                  subtitle:
                      'في ${WebGovernorateService.instance.governorateName}',
                ),
                TarfaSearchBar(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _filters = _filters.copyWith(query: v)),
                ),
                const SizedBox(height: TarfaTokens.s24),
                TarfaFiltersPanel(
                  filters: _filters,
                  onChanged: (f) => setState(() => _filters = f),
                  isGridView: _gridView,
                  onViewModeChanged: (v) => setState(() => _gridView = v),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<List<Store>>(
          stream: _catalog.watchStores(governorate: govName),
          builder: (context, snap) {
            final filtered = WebStoreFilters.apply(snap.data ?? [], _filters);

            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: TarfaTokens.s24,
                    crossAxisSpacing: TarfaTokens.s24,
                    childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const TarfaStoreCardSkeleton(),
                    childCount: 6,
                  ),
                ),
              );
            }

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'لا توجد متاجر مطابقة',
                    style: TarfaTokens.bodyLarge(context),
                  ),
                ),
              );
            }

            if (_gridView) {
              return SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: TarfaTokens.s24,
                    crossAxisSpacing: TarfaTokens.s24,
                    childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TarfaStoreCard(
                      store: filtered[index],
                      onTap: () => _openStore(filtered[index]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: TarfaTokens.s16),
                    child: TarfaStoreCard(
                      store: filtered[index],
                      compact: true,
                      onTap: () => _openStore(filtered[index]),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: TarfaTokens.s80)),
      ],
    );
  }
}
