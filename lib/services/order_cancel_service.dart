import 'package:cloud_functions/cloud_functions.dart';
import 'package:matlobgo/models/order.dart';

class OrderCancelService {
  OrderCancelService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> cancelOrder({
    required String orderId,
    String reason = 'customer_cancelled',
  }) async {
    try {
      await _functions.httpsCallable('cancelOrder').call({
        'orderId': orderId,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw OrderCancelException(_messageFor(e));
    }
  }

  static String _messageFor(FirebaseFunctionsException e) => switch (e.code) {
        'failed-precondition' when e.message?.contains('DELIVERED') == true =>
          'لا يمكن إلغاء طلب تم تسليمه',
        'permission-denied' => 'لا يمكنك إلغاء هذا الطلب',
        'not-found' => 'الطلب غير موجود',
        _ => 'تعذّر إلغاء الطلب — حاول مرة أخرى',
      };

  static bool canCustomerCancel(Order order) => order.canCustomerCancel;
}

class OrderCancelException implements Exception {
  OrderCancelException(this.message);
  final String message;
  @override
  String toString() => message;
}
