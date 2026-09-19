import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/profile/profile_controller.dart';

Order _order() => Order(
      id: '1',
      storeName: 'برجر تشاك',
      category: 'supplier',
      itemsSummary: 'غداء',
      itemCount: 1,
      total: 85,
      status: OrderStatus.delivered,
      createdAt: DateTime(2026, 7, 23, 14, 30),
    );

void main() {
  group('ProfileActivityFormat', () {
    test('title includes store name', () {
      expect(ProfileActivityFormat.title(_order()), 'طلب — برجر تشاك');
    });

    test('price uses EGP', () {
      expect(ProfileActivityFormat.price(_order()), contains('ج.م'));
    });

    test('relativeTime for yesterday-style clock', () {
      final text = ProfileActivityFormat.relativeTime(
        DateTime(2026, 7, 23, 14, 30),
      );
      expect(text.contains('2:30') || text.contains('14'), isTrue);
    });
  });
}
