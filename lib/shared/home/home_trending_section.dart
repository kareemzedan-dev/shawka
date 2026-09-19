import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/widgets/home_section_title.dart';
import 'package:matlobgo/screens/home/widgets/trending_horizontal_store_card.dart';

/// «الأكثر طلبًا» — identical to mobile home trending row.
class HomeTrendingSection extends StatelessWidget {
  const HomeTrendingSection({
    super.key,
    required this.stores,
    required this.onStoreTap,
  });

  final List<Store> stores;
  final void Function(Store store) onStoreTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeTheme.pageHorizontal,
            0,
            HomeTheme.pageHorizontal,
            HomeTheme.spaceSm,
          ),
          child: const HomeSectionTitle(
            title: '🔥 الأكثر طلبًا',
            padding: EdgeInsets.zero,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = TrendingCardLayout.cardWidthFor(
              constraints.maxWidth,
            );

            return SizedBox(
              height: TrendingCardLayout.listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                clipBehavior: Clip.none,
                padding: const EdgeInsetsDirectional.only(
                  start: HomeTheme.pageHorizontal,
                  end: HomeTheme.pageHorizontal,
                ),
                itemCount: stores.length,
                separatorBuilder: (_, _) => const SizedBox(
                  width: TrendingCardLayout.itemSpacing,
                ),
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return TrendingHorizontalStoreCard(
                    width: cardWidth,
                    store: store,
                    onTap: () => onStoreTap(store),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
