import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/shimmer_effect.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_feed.dart';

class HomeSkeletonSlivers {
  HomeSkeletonSlivers._();

  static List<Widget> build() {
    return const [
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.blockGap)),
      SliverToBoxAdapter(child: _BannerSkeleton()),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
      SliverToBoxAdapter(child: _SectionTitleSkeleton(width: 100)),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.itemGap)),
      SliverToBoxAdapter(child: _CategoriesSkeleton()),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
      SliverToBoxAdapter(child: _SectionTitleSkeleton(width: 140)),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.itemGap)),
      SliverToBoxAdapter(child: _FeaturedSkeleton()),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
      SliverToBoxAdapter(child: _SectionTitleSkeleton(width: 120)),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.itemGap)),
      SliverToBoxAdapter(child: _TrendingSkeleton()),
      SliverToBoxAdapter(child: SizedBox(height: HomeTheme.sectionGap)),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StoreListSkeleton(),
              SizedBox(height: 12),
              _StoreListSkeleton(),
              SizedBox(height: 12),
              _StoreListSkeleton(),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => const ShimmerBox(
          width: 300,
          height: 260,
          borderRadius: 24,
        ),
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ShimmerBox(
            width: constraints.maxWidth,
            height: 152,
            borderRadius: 20,
          );
        },
      ),
    );
  }
}

class _SectionTitleSkeleton extends StatelessWidget {
  const _SectionTitleSkeleton({this.width = 160});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
      child: Row(
        children: [
          ShimmerBox(width: width, height: 18, borderRadius: 8),
          const Spacer(),
          const ShimmerBox(width: 56, height: 14, borderRadius: 8),
        ],
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (_) => const Expanded(
            child: Column(
              children: [
                ShimmerBox(width: 58, height: 58, borderRadius: 29),
                SizedBox(height: 6),
                ShimmerBox(width: 44, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MatlobHomeCardMetrics.trendingListHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const ShimmerBox(
          width: 260,
          height: MatlobHomeCardMetrics.trendingListHeight,
          borderRadius: 20,
        ),
      ),
    );
  }
}

class _StoreListSkeleton extends StatelessWidget {
  const _StoreListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(
      width: double.infinity,
      height: 96,
      borderRadius: 20,
    );
  }
}
