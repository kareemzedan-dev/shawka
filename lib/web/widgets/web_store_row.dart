import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/widgets/trending_horizontal_store_card.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/widgets/web_premium_store_card.dart';

class WebStoreHorizontalSection extends StatelessWidget {
  const WebStoreHorizontalSection({
    super.key,
    required this.stores,
    this.featured = false,
    this.useTrendingCard = false,
  });

  final List<Store> stores;
  final bool featured;
  final bool useTrendingCard;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();

    if (useTrendingCard) {
      return SizedBox(
        height: TrendingCardLayout.listHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
          itemCount: stores.length,
          separatorBuilder: (_, _) =>
              const SizedBox(width: TrendingCardLayout.itemSpacing),
          itemBuilder: (context, index) {
            final store = stores[index];
            return TrendingHorizontalStoreCard(
              width: 260,
              store: store,
              onTap: () => _openStore(context, store),
            );
          },
        ),
      );
    }

    final cardWidth = featured ? 248.0 : 200.0;

    return SizedBox(
      height: featured ? 230 : 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
        itemCount: stores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final store = stores[index];
          return WebPremiumStoreCard(
            width: cardWidth,
            store: store,
            size: featured
                ? WebPremiumCardSize.featured
                : WebPremiumCardSize.horizontal,
            onTap: () => _openStore(context, store),
          );
        },
      ),
    );
  }

  void _openStore(BuildContext context, Store store) {
    WebConversionService.instance.recordStoreVisit(store.id);
    context.push(WebConstants.storePath(store.id));
  }
}

class WebStoreGrid extends StatelessWidget {
  const WebStoreGrid({
    super.key,
    required this.stores,
    this.onLoadMore,
    this.hasMore = false,
  });

  final List<Store> stores;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final cross = MediaQuery.sizeOf(context).width > 900
        ? 4
        : MediaQuery.sizeOf(context).width > 600
            ? 3
            : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HomeTheme.pageHorizontal,
        0,
        HomeTheme.pageHorizontal,
        24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: stores.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMore && index == stores.length) {
          return Center(
            child: OutlinedButton(
              onPressed: onLoadMore,
              child: const Text('تحميل المزيد'),
            ),
          );
        }
        final store = stores[index];
        return WebPremiumStoreCard(
          store: store,
          onTap: () {
            WebConversionService.instance.recordStoreVisit(store.id);
            context.push(WebConstants.storePath(store.id));
          },
        );
      },
    );
  }
}
