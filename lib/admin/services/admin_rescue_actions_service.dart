import 'package:cloud_functions/cloud_functions.dart';
import 'package:matlobgo/admin/services/admin_order_assignment_service.dart';

class AdminRescueActionsService {
  AdminRescueActionsService({
    AdminOrderAssignmentService? assignment,
    FirebaseFunctions? functions,
  })  : _assignment = assignment ?? AdminOrderAssignmentService(),
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final AdminOrderAssignmentService _assignment;
  final FirebaseFunctions _functions;

  Future<void> retryAssignment(String orderId) async {
    await _assignment.triggerAutoAssignment(
      orderId: orderId,
      reason: 'rescue_retry_assignment',
    );
  }

  Future<void> assignManually({
    required String orderId,
    required String driverId,
  }) async {
    await _assignment.assignDriverManually(
      orderId: orderId,
      driverId: driverId,
      reason: 'rescue_manual_assign',
    );
  }

  Future<void> cancelOrder(String orderId) async {
    await _functions.httpsCallable('cancelOrder').call({
      'orderId': orderId,
      'reason': 'admin_rescue_cancel',
    });
  }
}
