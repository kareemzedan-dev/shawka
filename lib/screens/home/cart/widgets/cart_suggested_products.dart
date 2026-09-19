import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/product.dart';

class CartSuggestedProductsSection extends StatelessWidget {
  const CartSuggestedProductsSection({
    super.key,
    required this.title,
    required this.products,
    required this.loading,
    required this.onAdd,
  });

  final String title;
  final List<Product> products;
  final bool loading;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    if (!loading && products.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(
              title,
              style: CartTypography.style(
                fontSize: CartTokens.sectionTitleSize,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: CartTokens.spaceLg),
          SizedBox(
            height: 168,
            child: loading
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: CartTokens.spaceMd),
                    itemBuilder: (_, _) => Semantics(
                      label: 'تحميل مقترح',
                      child: Container(
                        width: CartTokens.suggestionWidth,
                        decoration: BoxDecoration(
                          color: CartTokens.surfaceMuted,
                          borderRadius:
                              BorderRadius.circular(CartTokens.radiusMd),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: CartTokens.spaceMd),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _SuggestionCard(
                        product: product,
                        onAdd: () => onAdd(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label:
          'مقترح ${product.name}. السعر ${product.price.toStringAsFixed(0)} جنيه. إضافة إلى السلة',
      onTap: onAdd,
      child: Container(
        width: CartTokens.suggestionWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CartTokens.radiusMd),
          boxShadow: CartTokens.suggestionShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: CartTokens.suggestionImageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: CatalogNetworkImage(
                      imageUrl: product.imageUrl,
                      thumbnailUrl: product.imageThumbUrl,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: CartTokens.surfaceMuted,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: CartTokens.spaceSm,
                    bottom: CartTokens.spaceSm,
                    child: Material(
                      color: AppColors.navy,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onAdd();
                        },
                        child: const SizedBox(
                          width: CartTokens.suggestionAddButton,
                          height: CartTokens.suggestionAddButton,
                          child: Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(CartTokens.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: CartTokens.accentText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
