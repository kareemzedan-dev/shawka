import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/staggered_fade_in.dart';
import 'package:matlobgo/screens/home/category_browse_screen.dart';
import 'package:matlobgo/screens/home/search/search_controller.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';
import 'package:matlobgo/screens/home/search/widgets/search_categories_carousel.dart';
import 'package:matlobgo/screens/home/search/widgets/search_filter_chips.dart';
import 'package:matlobgo/screens/home/search/widgets/search_filter_sheet.dart';
import 'package:matlobgo/screens/home/search/widgets/search_hero_header.dart';
import 'package:matlobgo/screens/home/search/widgets/search_popular_chips.dart';
import 'package:matlobgo/screens/home/search/widgets/search_recent_list.dart';
import 'package:matlobgo/screens/home/search/widgets/search_results_list.dart';
import 'package:matlobgo/screens/home/search/widgets/search_state_views.dart';
import 'package:matlobgo/screens/home/search/widgets/search_store_card.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';

/// شاشة البحث — تكوين رفيع فقط (Controller + Widgets).
///
/// Reference Implementation v5.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.governorate,
    required this.cartService,
    this.onBack,
  });

  final String governorate;
  final CartService cartService;

  /// عند الاستخدام كتبويب داخل [HomeScreen] — الرجوع للرئيسية بدل `Navigator.pop`.
  final VoidCallback? onBack;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchScreenController(
      governorate: widget.governorate,
      cartService: widget.cartService,
    );
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final notice = _controller.notice;
    if (notice != null) {
      _showNotice(notice);
      _controller.clearNotice();
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: CartTypography.style(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _openFilters() async {
    final next = await showSearchFilterSheet(
      context,
      current: _controller.advancedFilters,
    );
    if (next != null) _controller.updateAdvancedFilters(next);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _controller,
          CmsTextService.instance,
        ]),
        builder: (context, _) {
          return PopScope(
            canPop: widget.onBack == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && widget.onBack != null) widget.onBack!();
            },
            child: Scaffold(
              backgroundColor: SearchTokens.heroNavy,
              resizeToAvoidBottomInset: true,
              body: Column(
                children: [
                  SearchHeroHeader(
                    topPadding: top,
                    controller: _controller.textController,
                    focusNode: _controller.focusNode,
                    hintText: _controller.searchHint,
                    title: _controller.pageTitle,
                    onChanged: _controller.onQueryChanged,
                    onBack: _handleBack,
                    onFilterTap: () => unawaited(_openFilters()),
                    onVoiceTap: _controller.requestVoiceSearch,
                    onClear: _controller.clearQuery,
                    hasText: _controller.query.isNotEmpty,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(SearchTokens.bodyTopRadius),
                      ),
                      child: ColoredBox(
                        color: SearchTokens.bodyBackground,
                        child: PremiumBackground.body(
                          context,
                          _buildBody(),
                        ),
                      ),
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

  Widget _buildBody() {
    final phase = _controller.phase;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (phase == SearchUiPhase.loading) {
      return const SearchSkeletonList();
    }
    if (phase == SearchUiPhase.offline) {
      return Column(
        children: [
          const SearchOfflineBanner(),
          Expanded(
            child: SearchErrorView(onRetry: () => unawaited(_controller.refresh())),
          ),
        ],
      );
    }
    if (phase == SearchUiPhase.error) {
      return SearchErrorView(onRetry: () => unawaited(_controller.refresh()));
    }

    if (_controller.hasQuery) {
      if (phase == SearchUiPhase.empty) {
        return SearchEmptyView(onClear: _controller.clearQuery);
      }
      return Column(
        children: [
          if (_controller.offline) const SearchOfflineBanner(),
          SearchFilterChips(
            categories: _controller.categories,
            selectedCategoryId: _controller.categoryId,
            onSelected: _controller.selectCategory,
            allLabel: _controller.filterAllLabel,
          ),
          Expanded(
            child: SearchResultsList(
              hits: _controller.visibleHits,
              canLoadMore: _controller.canLoadMore,
              onLoadMore: _controller.loadMore,
              onStoreTap: (store) =>
                  unawaited(_controller.openStore(context, store)),
              onProductTap: (store, product) => unawaited(
                _controller.openProduct(
                  context,
                  store: store,
                  product: product,
                ),
              ),
              onCategoryTap: (cat) => _controller.selectCategory(cat.id),
            ),
          ),
        ],
      );
    }

    final suggestedTitle = _controller.suggestedStoresTitle.trim();
    final suggestedSubtitle = _controller.suggestedStoresSubtitle.trim();
    final showSuggestedHeader = suggestedTitle.isNotEmpty;
    final showSuggestedStores =
        showSuggestedHeader && _controller.suggestedStores.isNotEmpty;

    return Column(
      children: [
        if (_controller.offline) const SearchOfflineBanner(),
        if (!keyboardOpen) ...[
          const SizedBox(height: 12),
          SearchCategoriesCarousel(
            categories: _controller.categories,
            onTapCategory: (cat) {
              unawaited(
                CategoryBrowseScreen.open(
                  context,
                  governorate: widget.governorate,
                  category: cat,
                  cartService: widget.cartService,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
        SearchFilterChips(
          categories: _controller.categories,
          selectedCategoryId: _controller.categoryId,
          onSelected: _controller.selectCategory,
          allLabel: _controller.filterAllLabel,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: SearchTokens.space3xl),
            children: [
              if (!keyboardOpen) ...[
                SearchRecentList(
                  searches: _controller.recentSearches,
                  onTap: _controller.applySuggestion,
                  onRemove: (q) => unawaited(_controller.removeRecent(q)),
                  onClearAll: () => unawaited(_controller.clearRecent()),
                  title: _controller.recentTitle,
                  clearLabel: _controller.recentClearLabel,
                ),
                SearchPopularChips(
                  terms: _controller.popularTerms,
                  onTap: _controller.applySuggestion,
                  title: _controller.popularTitle,
                ),
              ],
              if (showSuggestedHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SearchTokens.pagePadding,
                    SearchTokens.space2xl,
                    SearchTokens.pagePadding,
                    SearchTokens.spaceSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestedTitle,
                        style: CartTypography.style(
                          fontSize: SearchTokens.sectionTitleSize,
                          fontWeight: FontWeight.w800,
                          color: SearchTokens.textPrimary,
                        ),
                      ),
                      if (suggestedSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          suggestedSubtitle,
                          style: CartTypography.style(
                            fontSize: SearchTokens.captionSize,
                            fontWeight: FontWeight.w600,
                            color: SearchTokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (showSuggestedStores)
                ...List.generate(_controller.suggestedStores.length, (i) {
                  final store = _controller.suggestedStores[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SearchTokens.pagePadding,
                      0,
                      SearchTokens.pagePadding,
                      14,
                    ),
                    child: StaggeredFadeIn(
                      index: i,
                      child: SearchStoreCard(
                        store: store,
                        showPopularBadge: i == 0,
                        onTap: () =>
                            unawaited(_controller.openStore(context, store)),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
