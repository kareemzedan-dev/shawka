import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_search_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/utils/web_store_filters.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_filters_panel.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_search_bar.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_store_card.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_skeleton.dart';

class TarfaSearchScreen extends StatefulWidget {
  const TarfaSearchScreen({
    super.key,
    required this.govId,
    this.initialQuery = '',
  });

  final String govId;
  final String initialQuery;

  @override
  State<TarfaSearchScreen> createState() => _TarfaSearchScreenState();
}

class _TarfaSearchScreenState extends State<TarfaSearchScreen> {
  final _catalog = CatalogService();
  final _search = WebSearchService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<WebSearchHit> _hits = [];
  bool _loading = false;
  WebStoreFilterState _filters = const WebStoreFilterState();
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    WebGovernorateService.instance.setGovernorateById(widget.govId);
    WebSeoService.instance.apply(
      title: 'بحث — ${WebGovernorateService.instance.governorateName}',
      canonicalPath: '/g/${widget.govId}/search',
    );
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), _runSearch);
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final gov = WebGovernorateService.instance.governorateName;
    final stores = await _catalog.watchStores(governorate: gov).first;
    final cats = await _catalog.watchCategories(gov).first;
    final hits = await _search.search(
      governorate: gov,
      query: _controller.text,
      stores: stores,
      categories: cats,
    );
    if (mounted) {
      setState(() {
        _hits = hits;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;
    final padding = isMobile ? TarfaTokens.s16 : TarfaTokens.s48;
    final crossAxisCount = isMobile ? 1 : 3;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, TarfaTokens.s32, padding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ابحث', style: TarfaTokens.headlineLarge(context)),
                const SizedBox(height: TarfaTokens.s8),
                Text(
                  'اكتشف موردين ومنتجات وتصنيفات في ${WebGovernorateService.instance.governorateName}',
                  style: TarfaTokens.bodyLarge(context),
                ),
                const SizedBox(height: TarfaTokens.s24),
                TarfaSearchBar(
                  controller: _controller,
                  autofocus: true,
                  large: true,
                  onSubmitted: (_) => _runSearch(),
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
        if (_loading)
          SliverPadding(
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
          )
        else if (_hits.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: TarfaTokens.textMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: TarfaTokens.s16),
                  Text(
                    'لا توجد نتائج',
                    style: TarfaTokens.titleLarge(context),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: _gridView
                ? SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: TarfaTokens.s24,
                      crossAxisSpacing: TarfaTokens.s24,
                      childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hit = _hits[index];
                        if (hit.store == null || !hit.isStore) {
                          return _SearchHitCard(hit: hit);
                        }
                        return TarfaStoreCard(
                          store: hit.store!,
                          onTap: () => context.push(
                            WebConstants.storePath(hit.store!.id),
                          ),
                        );
                      },
                      childCount: _hits.length,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hit = _hits[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: TarfaTokens.s16,
                          ),
                          child: hit.isStore && hit.store != null
                              ? TarfaStoreCard(
                                  store: hit.store!,
                                  compact: true,
                                  onTap: () => context.push(
                                    WebConstants.storePath(hit.store!.id),
                                  ),
                                )
                              : _SearchHitCard(hit: hit),
                        );
                      },
                      childCount: _hits.length,
                    ),
                  ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: TarfaTokens.s80)),
      ],
    );
  }
}

class _SearchHitCard extends StatelessWidget {
  const _SearchHitCard({required this.hit});

  final WebSearchHit hit;

  String get _title {
    if (hit.isStore && hit.store != null) return hit.store!.name;
    if (hit.isProduct && hit.product != null) return hit.product!.name;
    if (hit.isCategory && hit.category != null) return hit.category!.name;
    return 'نتيجة';
  }

  String? get _subtitle {
    if (hit.isStore && hit.store != null) {
      final s = hit.store!;
      return '${s.rating.toStringAsFixed(1)} ★ · ${s.deliveryMinutes} د';
    }
    if (hit.isProduct && hit.product != null && hit.store != null) {
      return '${hit.product!.price.toStringAsFixed(0)} ج.م · ${hit.store!.name}';
    }
    if (hit.isCategory && hit.category != null) {
      return 'تصنيف · ${hit.category!.governorate}';
    }
    return null;
  }

  IconData get _icon {
    if (hit.isStore) return Icons.storefront_rounded;
    if (hit.isProduct) return Icons.fastfood_rounded;
    if (hit.isCategory) return Icons.category_rounded;
    return Icons.search_rounded;
  }

  void _onTap(BuildContext context) {
    if (hit.isStore && hit.store != null) {
      context.push(WebConstants.storePath(hit.store!.id));
    } else if (hit.isProduct &&
        hit.store != null &&
        hit.product != null) {
      context.push(
        WebConstants.productPath(hit.store!.id, hit.product!.id),
      );
    } else if (hit.isCategory && hit.category != null) {
      context.push(
        WebConstants.categoryPath(
          WebGovernorateService.instance.governorateId,
          hit.category!.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TarfaTokens.surface,
      borderRadius: TarfaTokens.borderRadius,
      elevation: 0,
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: TarfaTokens.borderRadius,
        child: Container(
          padding: const EdgeInsets.all(TarfaTokens.s16),
          decoration: BoxDecoration(
            borderRadius: TarfaTokens.borderRadius,
            boxShadow: TarfaTokens.shadowSm,
          ),
          child: Row(
            children: [
              Icon(_icon, color: TarfaTokens.secondary, size: 28),
              const SizedBox(width: TarfaTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: TarfaTokens.titleMedium(context)),
                    if (_subtitle != null)
                      Text(
                        _subtitle!,
                        style: TarfaTokens.bodyMedium(context),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_rounded, color: TarfaTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
