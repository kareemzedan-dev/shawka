import 'package:cloud_functions/cloud_functions.dart';

class AssignmentActionResult {
  const AssignmentActionResult({
    required this.ok,
    this.message = '',
    this.offeredDriverId,
    this.driverId,
    this.driverName,
    this.assignmentStatus,
  });

  final bool ok;
  final String message;
  final String? offeredDriverId;
  final String? driverId;
  final String? driverName;
  final String? assignmentStatus;
}

/// Admin order assignment — uses Assignment Engine Cloud Functions.
class AdminOrderAssignmentService {
  AdminOrderAssignmentService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<AssignmentActionResult> triggerAutoAssignment({
    required String orderId,
    String reason = 'admin_trigger_auto',
  }) async {
    final result = await _functions.httpsCallable('adminReassignDelivery').call({
      'orderId': orderId,
      'mode': 'auto',
      'reason': reason,
    });
    return _parse(result.data);
  }

  Future<AssignmentActionResult> assignDriverManually({
    required String orderId,
    required String driverId,
    String reason = 'admin_manual_override',
  }) async {
    final result = await _functions.httpsCallable('adminReassignDelivery').call({
      'orderId': orderId,
      'mode': 'manual',
      'driverId': driverId,
      'force': true,
      'reason': reason,
    });
    return _parse(result.data);
  }

  AssignmentActionResult _parse(dynamic raw) {
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return AssignmentActionResult(
      ok: data['ok'] == true,
      message: '${data['message'] ?? ''}',
      offeredDriverId: data['offeredDriverId'] as String?,
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
      assignmentStatus: data['assignmentStatus'] as String?,
    );
  }
}
