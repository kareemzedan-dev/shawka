import 'package:matlobgo/admin/services/ops_incident_repository.dart';
import 'package:matlobgo/models/order.dart';

enum RescueFailureType {
  assignmentFailed,
  noDriverFound,
  driverTimeout,
  autoReassignFailed,
  driverUnresponsive,
  gpsFraud,
}

extension RescueFailureTypeX on RescueFailureType {
  String get label => switch (this) {
        RescueFailureType.assignmentFailed => 'Assignment Failed',
        RescueFailureType.noDriverFound => 'No Driver Found',
        RescueFailureType.driverTimeout => 'Driver Timeout',
        RescueFailureType.autoReassignFailed => 'Auto Reassign Failed',
        RescueFailureType.driverUnresponsive => 'Driver Unresponsive',
        RescueFailureType.gpsFraud => 'GPS Fraud',
      };
}

class RescueOrderItem {
  const RescueOrderItem({
    required this.order,
    required this.type,
    required this.detectedAt,
    required this.ageMinutes,
    this.incidentId,
  });

  final Order order;
  final RescueFailureType type;
  final DateTime detectedAt;
  final int ageMinutes;
  final String? incidentId;
}

class RescueKpis {
  const RescueKpis({
    required this.queueCount,
    required this.avgRescueMinutes,
    required this.resolvedToday,
  });

  final int queueCount;
  final double? avgRescueMinutes;
  final int resolvedToday;
}

abstract final class AdminRescueService {
  static List<RescueOrderItem> buildQueue({
    required List<Order> orders,
    required List<OpsIncident> incidents,
    String? governorateFilter,
    RescueFailureType? typeFilter,
    int? maxAgeMinutes,
  }) {
    final now = DateTime.now();
    var filtered = orders;
    if (governorateFilter != null && governorateFilter.isNotEmpty) {
      filtered =
          orders.where((o) => o.governorate == governorateFilter).toList();
    }

    final incidentByOrder = <String, OpsIncident>{};
    for (final inc in incidents) {
      final oid = inc.orderId;
      if (oid == null || oid.isEmpty) continue;
      incidentByOrder.putIfAbsent(oid, () => inc);
    }

    final items = <RescueOrderItem>[];

    for (final order in filtered) {
      if (order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled) {
        continue;
      }

      RescueFailureType? type;
      DateTime detectedAt = order.updatedAt ?? order.createdAt;

      if (order.watchdogCriticalAt != null) {
        type = RescueFailureType.driverUnresponsive;
        detectedAt = order.watchdogCriticalAt!;
      } else if (order.assignmentStatus == 'failed') {
        type = RescueFailureType.assignmentFailed;
      } else if (order.deliveryRejectReason == 'timeout') {
        type = RescueFailureType.driverTimeout;
        detectedAt = order.offeredAt ?? detectedAt;
      } else {
        final inc = incidentByOrder[order.id];
        if (inc != null) {
          type = switch (inc.type) {
            'assignment_exhausted' => RescueFailureType.noDriverFound,
            'auto_reassign_stale_driver' => RescueFailureType.autoReassignFailed,
            'driver_unresponsive' => RescueFailureType.driverUnresponsive,
            'gps_fraud_pickup' || 'gps_fraud_delivered' =>
              RescueFailureType.gpsFraud,
            _ => null,
          };
          detectedAt = inc.createdAt ?? detectedAt;
        }
      }

      if (type == null) continue;

      final ageMin = now.difference(detectedAt).inMinutes;
      if (maxAgeMinutes != null && ageMin > maxAgeMinutes) continue;
      if (typeFilter != null && type != typeFilter) continue;

      items.add(
        RescueOrderItem(
          order: order,
          type: type,
          detectedAt: detectedAt,
          ageMinutes: ageMin,
          incidentId: incidentByOrder[order.id]?.id,
        ),
      );
    }

    items.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return items;
  }

  static RescueKpis computeKpis({
    required List<RescueOrderItem> queue,
    required List<OpsIncident> incidents,
  }) {
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final resolvedToday = incidents.where((i) {
      if (i.resolutionStatus != 'resolved') return false;
      final createdAt = i.createdAt;
      if (createdAt == null) return false;
      return !createdAt.isBefore(todayStart);
    }).length;

    final ages = queue.map((e) => e.ageMinutes.toDouble()).toList();
    final avg = ages.isEmpty
        ? null
        : ages.reduce((a, b) => a + b) / ages.length;

    return RescueKpis(
      queueCount: queue.length,
      avgRescueMinutes: avg,
      resolvedToday: resolvedToday,
    );
  }
}
