import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/product_addon.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';
import 'package:matlobgo/screens/home/product/widgets/product_add_to_cart_bar.dart';
import 'package:matlobgo/screens/home/product/widgets/product_addons.dart';
import 'package:matlobgo/screens/home/product/widgets/product_attributes.dart';
import 'package:matlobgo/screens/home/product/widgets/product_description_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_hero.dart';
import 'package:matlobgo/screens/home/product/widgets/product_notes_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_price_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_quantity_card.dart';
import 'package:matlobgo/screens/home/product/widgets/product_suggested_section.dart';

/// تكوين بصري ثابت لتفاصيل المنتج (Golden + Profile) بدون Firebase.
Store productPreviewStore() => Store(
      id: 'store_1',
      name: 'مطعم الذواقة',
      categoryId: 'supplier',
      rating: 4.7,
      deliveryMinutes: 30,
      deliveryFee: 15,
      fallbackOpen: true,
      tags: const [],
      governorate: 'القاهرة',
      logoUrl: null,
    );

Product productPreviewProduct() => const Product(
      id: 'product_1',
      storeId: 'store_1',
      name: 'برجر لحم أنجوس مشوي',
      price: 120,
      oldPrice: 150,
      rating: 4.6,
      reviewCount: 214,
      ordersCount: 340,
      preparationTime: 20,
      calories: 640,
      portionSize: 'فردي',
      natureLabel: 'حار',
      bestSeller: true,
      description:
          'برجر لحم أنجوس طازج مشوي على الفحم مع جبنة شيدر وصوص المطعم الخاص '
          'وخضار مقرمشة في خبز بريوش.',
      ingredients: ['لحم أنجوس', 'جبنة شيدر', 'خس', 'طماطم', 'صوص خاص'],
      addons: [
        ProductAddon(id: 'a1', name: 'جبنة إضافية', price: 10),
        ProductAddon(id: 'a2', name: 'بطاطس', price: 20),
      ],
    );

Product productPreviewSuggestion({
  String id = 'product_2',
  String name = 'أجنحة دجاج',
  double price = 75,
  double rating = 4.4,
}) =>
    Product(
      id: id,
      storeId: 'store_1',
      name: name,
      price: price,
      rating: rating,
    );

List<Product> productPreviewSuggestions() => [
      productPreviewSuggestion(),
      productPreviewSuggestion(
        id: 'product_3',
        name: 'بطاطس مقلية',
        price: 35,
        rating: 4.2,
      ),
      productPreviewSuggestion(
        id: 'product_4',
        name: 'عصير برتقال',
        price: 25,
        rating: 4.8,
      ),
    ];

/// شاشة معاينة كاملة (محمّلة) — بلا Controller/Firebase.
class ProductPreviewScreen extends StatefulWidget {
  const ProductPreviewScreen({
    super.key,
    this.suggestionsLoading = false,
    this.quantity = 2,
  });

  final bool suggestionsLoading;
  final int quantity;

  @override
  State<ProductPreviewScreen> createState() => _ProductPreviewScreenState();
}

class _ProductPreviewScreenState extends State<ProductPreviewScreen> {
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = productPreviewStore();
    final product = productPreviewProduct();
    final suggestions =
        widget.suggestionsLoading ? const <Product>[] : productPreviewSuggestions();
    final unitPrice = product.price + 30;

    return ColoredBox(
      color: ProductTokens.sheet,
      child: Stack(
        children: [
          CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductHero(
                      store: store,
                      product: product,
                      isFavorite: true,
                      onBack: () {},
                      onShare: () {},
                      onToggleFavorite: () {},
                    ),
                    Transform.translate(
                      offset: const Offset(0, -ProductTokens.sheetOverlap),
                      child: _sheet(store, product, suggestions),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ProductAddToCartBar(
              state: ProductCtaState.normal,
              total: unitPrice * widget.quantity,
              unavailableReason: null,
              onAdd: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheet(Store store, Product product, List<Product> suggestions) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ProductTokens.sheet,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ProductTokens.sheetRadius),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        ProductTokens.pagePadding,
        ProductTokens.space3xl,
        ProductTokens.pagePadding,
        ProductTokens.space3xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductPriceSection(product: product),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductDescriptionSection(product: product, storeName: store.name),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductAttributes(product: product),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductAddons(
            addons: product.addons,
            selectedIds: const {'a1'},
            onToggle: (_) {},
          ),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductQuantityCard(
            quantity: widget.quantity,
            canIncrement: true,
            canDecrement: true,
            onIncrement: () {},
            onDecrement: () {},
          ),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductNotesSection(
            controller: _notes,
            length: 0,
            maxLength: 200,
            onChanged: (_) {},
          ),
          const SizedBox(height: ProductTokens.space3xl + 8),
          ProductSuggestedSection(
            products: suggestions,
            loading: widget.suggestionsLoading,
            onViewAll: () {},
            onProductTap: (_) {},
            onAdd: (_) {},
          ),
        ],
      ),
    );
  }
}

/// معاينة قسم المقترحات في حالة التحميل (هيكل ثابت) للـ Golden.
class ProductSuggestionsLoadingPreview extends StatelessWidget {
  const ProductSuggestionsLoadingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(ProductTokens.pagePadding),
        child: ProductSuggestedSection(
          products: const [],
          loading: true,
          onViewAll: () {},
          onProductTap: (_) {},
          onAdd: (_) {},
        ),
      ),
    );
  }
}
