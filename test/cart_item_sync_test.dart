import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/cart_item.dart';

void main() {
  test('CartItem sync fields support realtime stock and discount', () {
    final item = CartItem(
      id: 's1_p1',
      storeId: 's1',
      productId: 'p1',
      storeName: 'Store',
      category: 'supplier',
      productName: 'Sandwich',
      price: 10,
      quantity: 2,
      trackStock: true,
      stockQuantity: 5,
      maxPerCustomer: 3,
      discountPercent: 10,
    );

    expect(item.maxOrderQuantity, 3);

    final updated = item.copyWith(price: 12, stockQuantity: 1, quantity: 3);
    expect(updated.price, 12);
    expect(updated.stockQuantity, 1);
    expect(updated.maxOrderQuantity, 1);
    expect(updated.discountPercent, 10);
    expect(updated.lineTotal, 36);
  });
}
