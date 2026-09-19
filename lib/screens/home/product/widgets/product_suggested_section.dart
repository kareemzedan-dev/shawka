import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/product.dart';

/// قسم «أكمل وجبتك» + «عرض الكل» + بطاقات أفقية (صورة، شارة تقييم، اسم، سعر، +).
class ProductSuggestedSection extends StatelessWidget {
  const ProductSuggestedSection({
    super.key,
    required this.products,
    required this.loading,
    required this.onViewAll,
    required this.onProductTap,
    required this.onAdd,
  });

  final List<Product> products;
  final bool loading;
  final VoidCallback onViewAll;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && !loading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'أكمل وجبتك',
                style: CartTypography.style(
                  fontSize: ProductTokens.sectionTitleSize,
                  fontWeight: FontWeight.w800,
                  color: ProductTokens.textPrimary,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'عرض كل منتجات المتجر',
              child: TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: ProductTokens.accentText,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'عرض الكل',
                  style: CartTypography.style(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ProductTokens.accentText,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ProductTokens.spaceLg),
        SizedBox(
          height: 214,
          child: loading && products.isEmpty
              ? const _SuggestionSkeletonRow()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: EdgeInsets.zero,
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: ProductTokens.spaceLg),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _SuggestionCard(
                      product: product,
                      onTap: () => onProductTap(product),
                      onAdd: () => onAdd(product),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${product.name} ${product.price.toStringAsFixed(0)} جنيه',
      child: SizedBox(
        width: ProductTokens.suggestionWidth,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ProductTokens.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: ProductTokens.suggestionImageHeight,
                      width: double.infinity,
                      child: CatalogNetworkImage(
                        imageUrl: product.imageUrl,
                        thumbnailUrl: product.imageThumbUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 320,
                        cacheHeight: 220,
                        fallback: const ColoredBox(
                          color: ProductTokens.cardFill,
                          child: Icon(
                            Icons.fastfood_rounded,
                            color: ProductTokens.textMuted,
                          ),
                        ),
                      ),
                    ),
                    if (product.rating > 0)
                      PositionedDirectional(
                        top: ProductTokens.spaceSm,
                        start: ProductTokens.spaceSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ProductTokens.heroChipBackground,
                            borderRadius:
                                BorderRadius.circular(ProductTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: ProductTokens.star,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: CartTypography.style(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CartTypography.style(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ProductTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: ProductTokens.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${product.price.toStringAsFixed(0)} ج.م',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CartTypography.style(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: ProductTokens.accentText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _AddButton(onAdd: onAdd),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// هيكل تحميل ثابت (بلا حركة) — مناسب للـ goldens وأفضل من الدوّارة بصرياً.
class _SuggestionSkeletonRow extends StatelessWidget {
  const _SuggestionSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: ProductTokens.spaceLg),
      itemBuilder: (_, _) => const _SuggestionSkeletonCard(),
    );
  }
}

class _SuggestionSkeletonCard extends StatelessWidget {
  const _SuggestionSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جارٍ تحميل المقترحات',
      child: SizedBox(
        width: ProductTokens.suggestionWidth,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ProductTokens.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: ProductTokens.suggestionImageHeight,
                child: ColoredBox(color: ProductTokens.cardFill),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBar(width: double.infinity, height: 12),
                    const SizedBox(height: ProductTokens.spaceMd),
                    _skeletonBar(width: 64, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ProductTokens.fieldFill,
        borderRadius: BorderRadius.circular(ProductTokens.radiusSm),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'إضافة للسلة',
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: ProductTokens.suggestionAddButton,
            height: ProductTokens.suggestionAddButton,
            child: Icon(Icons.add_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
