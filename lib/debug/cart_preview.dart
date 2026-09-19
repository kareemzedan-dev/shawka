import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_free_delivery_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_header.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_item_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_summary_and_bar.dart';

/// تكوين بصري ثابت للسلة (Golden + Profile) بدون Firebase.
CartItem cartPreviewItem({
  String id = 'item_1',
  String name = 'برجر كلاسيك',
  double price = 85,
  int quantity = 2,
  bool available = true,
  bool trackStock = true,
  int stock = 8,
  double discount = 10,
}) {
  return CartItem(
    id: id,
    storeId: 'store_1',
    productId: 'product_1',
    storeName: 'متجر التجربة',
    category: 'supplier',
    productName: name,
    price: price,
    quantity: quantity,
    isAvailable: available,
    trackStock: trackStock,
    stockQuantity: stock,
    discountPercent: discount,
  );
}

class CartPreviewScreen extends StatelessWidget {
  const CartPreviewScreen({super.key, this.quantityOverride});

  final int? quantityOverride;

  @override
  Widget build(BuildContext context) {
    final item = cartPreviewItem(quantity: quantityOverride ?? 2);
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          CartHeader(
            title: 'سلة التسوق',
            subtitle: '2 أصناف في سلتك',
            onBack: () {},
          ),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    CartTokens.pagePadding,
                    0,
                    CartTokens.pagePadding,
                    CartTokens.listBottomClearance,
                  ),
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -CartTokens.freeCardOverlap),
                      child: Column(
                        children: [
                          const CartFreeDeliveryCard(
                            title: 'توصيل مجاني يقترب!',
                            body: 'أضف 40 ج.م للحصول على العرض',
                            progress: 0.72,
                            unlocked: false,
                          ),
                          const SizedBox(height: CartTokens.space2xl),
                          CartItemCard(
                            item: item,
                            onQuantityChanged: (_) {},
                            onRemove: () {},
                            onSwiped: () {},
                          ),
                          const SizedBox(height: CartTokens.space3xl),
                          const CartPriceSummary(
                            itemCount: 2,
                            subtotal: 170,
                            discount: 15,
                            subtotalLabel: 'المجموع الفرعي',
                            discountLabel: 'إجمالي الخصم',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CartContinueBar(
                    totalLabel: 'المجموع',
                    total: 155,
                    ctaLabel: 'متابعة الطلب',
                    onContinue: _noop,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
