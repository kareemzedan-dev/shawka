import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/tracking/tracking_controller.dart';

Order _order({
  OrderStatus status = OrderStatus.pending,
  String? deliveryId,
  int etaMinutes = 12,
}) =>
    Order(
      id: 'trk_1',
      storeName: 'متجر الاختبار',
      category: 'supplier',
      itemsSummary: 'اختبار',
      itemCount: 1,
      total: 50,
      status: status,
      createdAt: DateTime(2026, 7, 24, 20, 15),
      updatedAt: DateTime(2026, 7, 24, 20, 22),
      etaMinutes: etaMinutes,
      deliveryId: deliveryId,
      deliveryName: deliveryId == null ? null : 'مازن محمد',
      deliveryPhone: deliveryId == null ? null : '01000000000',
      deliveryVehicleType: deliveryId == null ? null : 'car',
    );

void main() {
  group('TrackingTimelineData', () {
    test('activeIndex maps status to 4-step timeline', () {
      expect(TrackingTimelineData.activeIndex(OrderStatus.pending), 0);
      expect(TrackingTimelineData.activeIndex(OrderStatus.preparing), 1);
      expect(TrackingTimelineData.activeIndex(OrderStatus.readyForPickup), 2);
      expect(TrackingTimelineData.activeIndex(OrderStatus.onTheWay), 2);
      expect(TrackingTimelineData.activeIndex(OrderStatus.delivered), 3);
      expect(TrackingTimelineData.activeIndex(OrderStatus.cancelled), -1);
    });

    test('statusTitle reflects driver-at-store when ready', () {
      final withDriver = _order(
        status: OrderStatus.readyForPickup,
        deliveryId: 'drv1',
      );
      expect(
        TrackingTimelineData.statusTitle(withDriver),
        'السائق في المتجر',
      );
    });

    test('etaMinutesLabel uses snapshot then order', () {
      final order = _order(status: OrderStatus.onTheWay, etaMinutes: 8);
      expect(
        TrackingTimelineData.etaMinutesLabel(order, 12),
        '12 دقيقة',
      );
      expect(
        TrackingTimelineData.etaMinutesLabel(order, 0),
        '8 دقيقة',
      );
      expect(
        TrackingTimelineData.etaMinutesLabel(
          _order(status: OrderStatus.delivered),
          5,
        ),
        '—',
      );
    });

    test('titles are four SSOT steps', () {
      expect(TrackingTimelineData.titles.length, 4);
      expect(TrackingTimelineData.titles.first, 'تم استلام الطلب');
      expect(TrackingTimelineData.titles.last, 'تم التوصيل');
    });
  });
}
