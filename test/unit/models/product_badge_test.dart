import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/product.dart';

Product _product({
  bool bestSeller = false,
  bool isNew = false,
  bool isFeatured = false,
  double discountPercent = 0,
  double oldPrice = 0,
  double price = 50,
  bool isAvailable = true,
  bool trackStock = false,
  int stockQuantity = 0,
}) {
  return Product(
    id: 'p1',
    storeId: 's1',
    name: 'منتج',
    price: price,
    bestSeller: bestSeller,
    isNew: isNew,
    isFeatured: isFeatured,
    discountPercent: discountPercent,
    oldPrice: oldPrice,
    isAvailable: isAvailable,
    trackStock: trackStock,
    stockQuantity: stockQuantity,
  );
}

void main() {
  group('Product.badgeLabel priority', () {
    test('bestSeller wins over everything', () {
      final product = _product(
        bestSeller: true,
        isNew: true,
        isFeatured: true,
        discountPercent: 30,
      );
      expect(product.badgeLabel, 'الأكثر مبيعاً');
    });

    test('isNew wins over discount and featured', () {
      final product = _product(
        isNew: true,
        isFeatured: true,
        discountPercent: 30,
      );
      expect(product.badgeLabel, 'جديد');
    });

    test('discount wins over featured', () {
      final product = _product(isFeatured: true, discountPercent: 25);
      expect(product.badgeLabel, 'خصم 25%');
    });

    test('discount derived from oldPrice when discountPercent is 0', () {
      final product = _product(oldPrice: 100, price: 75);
      expect(product.badgeLabel, 'خصم 25%');
    });

    test('featured is the last resort', () {
      final product = _product(isFeatured: true);
      expect(product.badgeLabel, 'مميز');
    });

    test('no badge when nothing applies', () {
      expect(_product().badgeLabel, isNull);
    });

    test('no badge when out of stock', () {
      final unavailable = _product(bestSeller: true, isAvailable: false);
      expect(unavailable.badgeLabel, isNull);

      final trackedOut = _product(
        bestSeller: true,
        trackStock: true,
        stockQuantity: 0,
      );
      expect(trackedOut.badgeLabel, isNull);
    });
  });
}
