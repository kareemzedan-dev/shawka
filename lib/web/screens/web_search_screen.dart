import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/screens/home/widgets/polish/polish_skeleton.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_search_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/widgets/web_premium_hero.dart';

class WebSearchScreen extends StatefulWidget {
  const WebSearchScreen({super.key, required this.govId, this.initialQuery = ''});

  final String govId;
  final String initialQuery;

  @override
  State<WebSearchScreen> createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends State<WebSearchScreen> {
  final _catalog = CatalogService();
  final _search = WebSearchService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<WebSearchHit> _hits = [];
  bool _loading = false;

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
    return PremiumBackground.body(
      context,
      CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WebPremiumHero(
              compact: true,
              onSearchSubmit: (_) => _runSearch(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مورد، منتج، أو تصنيف...',
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
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: PolishSkeleton(height: 72),
                ),
                childCount: 5,
              ),
            )
          else if (_hits.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'لا توجد نتائج',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SearchHitTile(hit: _hits[index]),
                childCount: _hits.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchHitTile extends StatelessWidget {
  const _SearchHitTile({required this.hit});

  final WebSearchHit hit;

  @override
  Widget build(BuildContext context) {
    if (hit.isCategory) {
      final cat = hit.category!;
      return ListTile(
        leading: const Icon(Icons.category_rounded, color: AppColors.primary),
        title: Text(cat.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        subtitle: const Text('تصنيف'),
        onTap: () => context.push(
          WebConstants.categoryPath(
            WebGovernorateService.instance.governorateId,
            cat.id,
          ),
        ),
      );
    }
    if (hit.isProduct) {
      final store = hit.store!;
      final product = hit.product!;
      return ListTile(
        leading: const Icon(Icons.fastfood_rounded, color: AppColors.primary),
        title: Text(product.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        subtitle: Text('${store.name} · ${product.price.toInt()} ج.م'),
        onTap: () => context.push(
          WebConstants.productPath(store.id, product.id),
        ),
      );
    }
    final store = hit.store!;
    return ListTile(
      leading: const Icon(Icons.storefront_rounded, color: AppColors.navy),
      title: Text(store.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      subtitle: Text('⭐ ${store.rating} · ${store.deliveryMinutes} د'),
      onTap: () => context.push(WebConstants.storePath(store.id)),
    );
  }
}
