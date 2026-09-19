import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/services/favorites_service.dart';

void main() {
  group('FavoritesService.productKey', () {
    test('joins storeId and productId with a colon', () {
      expect(FavoritesService.productKey('store1', 'prod9'), 'store1:prod9');
    });

    test('is unique per store/product pair', () {
      final keys = {
        FavoritesService.productKey('s1', 'p1'),
        FavoritesService.productKey('s1', 'p2'),
        FavoritesService.productKey('s2', 'p1'),
      };
      expect(keys.length, 3);
    });

    test('round-trips through the key format', () {
      const storeId = 'abc123';
      const productId = 'xyz789';
      final key = FavoritesService.productKey(storeId, productId);
      final separator = key.indexOf(':');
      expect(key.substring(0, separator), storeId);
      expect(key.substring(separator + 1), productId);
    });
  });
}
