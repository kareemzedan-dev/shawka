import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';

/// Operational metrics for the live ops dashboard.
class OperationsSnapshot {
  const OperationsSnapshot({
    required this.pendingAssignment,
    required this.offered,
    required this.active,
    required this.deliveredToday,
    required this.failedAssignments,
    required this.driversOnline,
    required this.driversOffline,
    required this.driversWithoutGps,
    required this.avgAcceptanceMinutes,
    required this.avgDeliveryMinutes,
    required this.activeByGovernorate,
    required this.warnings,
    required this.computedAt,
    required this.slaSuccessRate,
    required this.slaFailureRate,
    required this.avgFulfillmentMinutes,
  });

  final int pendingAssignment;
  final int offered;
  final int active;
  final int deliveredToday;
  final int failedAssignments;
  final int driversOnline;
  final int driversOffline;
  final int driversWithoutGps;
  final double? avgAcceptanceMinutes;
  final double? avgDeliveryMinutes;
  final Map<String, int> activeByGovernorate;
  final List<OpsWarning> warnings;
  final DateTime computedAt;
  final double slaSuccessRate;
  final double slaFailureRate;
  final double? avgFulfillmentMinutes;
}

class OpsWarning {
  const OpsWarning({required this.message, required this.severity});

  final String message;
  final OpsWarningSeverity severity;
}

enum OpsWarningSeverity { info, warning, critical }

class DriverWatchdogEntry {
  const DriverWatchdogEntry({
    required this.driverId,
    required this.driverName,
    required this.orderId,
    required this.storeName,
    required this.idleMinutes,
    required this.severity,
  });

  final String driverId;
  final String driverName;
  final String orderId;
  final String storeName;
  final int idleMinutes;
  final OpsWarningSeverity severity;
}

abstract final class AdminOperationsService {
  static const _slaTargetMinutes = 45;

  static OperationsSnapshot compute({
    required List<Order> orders,
    required List<AppUser> drivers,
    String? governorateFilter,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    var filtered = orders;
    if (governorateFilter != null && governorateFilter.isNotEmpty) {
      filtered = orders.where((o) => o.governorate == governorateFilter).toList();
    }

    final pendingAssignment = filtered.where(_isPendingAssignment).length;
    final offered = filtered.where(_isOffered).length;
    final active = filtered.where(_isActiveDelivery).length;
    final deliveredToday = filtered.where((o) {
      if (o.status != OrderStatus.delivered) return false;
      final at = o.deliveryDeliveredAt ?? o.createdAt;
      return !at.isBefore(todayStart);
    }).length;
    final failedAssignments =
        filtered.where((o) => o.assignmentStatus == 'failed').length;

    final approvedDrivers =
        drivers.where((d) => d.isDelivery && d.isActive).toList();
    final driversOnline =
        approvedDrivers.where((d) => d.isDriverOnlineEffective).length;
    final driversOffline = approvedDrivers.length - driversOnline;
    final driversWithoutGps = approvedDrivers
        .where((d) => d.isDriverOnlineEffective && !d.hasLiveLocation)
        .length;

    final acceptanceSamples = filtered
        .where((o) => o.offeredAt != null && o.deliveryAcceptedAt != null)
        .map((o) =>
            o.deliveryAcceptedAt!.difference(o.offeredAt!).inSeconds / 60.0)
        .toList();
    final deliverySamples = filtered
        .where((o) =>
            o.deliveryAcceptedAt != null && o.deliveryDeliveredAt != null)
        .map((o) => o.deliveryDeliveredAt!
            .difference(o.deliveryAcceptedAt!)
            .inSeconds /
            60.0)
        .toList();
    final fulfillmentSamples = filtered
        .where((o) => o.deliveryDeliveredAt != null)
        .map((o) =>
            o.deliveryDeliveredAt!.difference(o.createdAt).inSeconds / 60.0)
        .toList();

    final avgAcceptance = _avg(acceptanceSamples);
    final avgDelivery = _avg(deliverySamples);
    final avgFulfillment = _avg(fulfillmentSamples);

    final slaEvaluated = filtered
        .where((o) => o.deliveryDeliveredAt != null)
        .toList();
    final slaSuccess = slaEvaluated
        .where((o) {
          final mins = o.deliveryDeliveredAt!.difference(o.createdAt).inMinutes;
          return mins <= _slaTargetMinutes;
        })
        .length;
    final slaRate = slaEvaluated.isEmpty
        ? 100.0
        : (slaSuccess / slaEvaluated.length) * 100;
    final slaFailureRate = slaEvaluated.isEmpty ? 0.0 : 100 - slaRate;

    final activeByGov = <String, int>{};
    for (final o in filtered.where(_isActiveDelivery)) {
      final g = o.governorate.isEmpty ? 'غير محدد' : o.governorate;
      activeByGov[g] = (activeByGov[g] ?? 0) + 1;
    }

    final warnings = <OpsWarning>[
      if (failedAssignments >= 3)
        OpsWarning(
          message: '$failedAssignments طلبات بتخصيص فاشل — راجع المندوبين المتاحين',
          severity: OpsWarningSeverity.critical,
        ),
      if (pendingAssignment >= 5)
        OpsWarning(
          message: '$pendingAssignment طلبات جاهزة بانتظار مندوب',
          severity: OpsWarningSeverity.warning,
        ),
      if (offered >= 4)
        OpsWarning(
          message: '$offered عروض معلّقة — قد تنتهي صلاحيتها',
          severity: OpsWarningSeverity.warning,
        ),
      if (driversOnline == 0 && pendingAssignment > 0)
        OpsWarning(
          message: 'لا يوجد مندوبون متصلون والطلبات تنتظر',
          severity: OpsWarningSeverity.critical,
        ),
      if (driversWithoutGps >= 2)
        OpsWarning(
          message: '$driversWithoutGps مندوبون Online بدون GPS حديث',
          severity: OpsWarningSeverity.warning,
        ),
      if (avgAcceptance != null && avgAcceptance > 2)
        OpsWarning(
          message:
              'متوسط قبول العروض ${avgAcceptance.toStringAsFixed(1)} د — أعلى من المتوقع',
          severity: OpsWarningSeverity.info,
        ),
      if (slaFailureRate > 25 && slaEvaluated.length >= 3)
        OpsWarning(
          message:
              'معدل تجاوز SLA ${slaFailureRate.toStringAsFixed(0)}% — الهدف $_slaTargetMinutes د',
          severity: OpsWarningSeverity.warning,
        ),
    ];

    return OperationsSnapshot(
      pendingAssignment: pendingAssignment,
      offered: offered,
      active: active,
      deliveredToday: deliveredToday,
      failedAssignments: failedAssignments,
      driversOnline: driversOnline,
      driversOffline: driversOffline,
      driversWithoutGps: driversWithoutGps,
      avgAcceptanceMinutes: avgAcceptance,
      avgDeliveryMinutes: avgDelivery,
      activeByGovernorate: activeByGov,
      warnings: warnings,
      computedAt: now,
      slaSuccessRate: slaRate,
      slaFailureRate: slaFailureRate,
      avgFulfillmentMinutes: avgFulfillment,
    );
  }

  static bool _isPendingAssignment(Order o) {
    if (o.status == OrderStatus.cancelled || o.status == OrderStatus.delivered) {
      return false;
    }
    if (o.status != OrderStatus.readyForPickup) return false;
    if (o.deliveryId != null && o.deliveryId!.isNotEmpty) return false;
    final phase = o.deliveryPhase ?? '';
    if (phase == 'offered') return false;
    final st = o.assignmentStatus ?? '';
    return st.isEmpty ||
        st == 'searching' ||
        st == 'failed' ||
        st == 'unassigned';
  }

  static bool _isOffered(Order o) {
    return o.deliveryPhase == 'offered' ||
        o.assignmentStatus == 'offering' ||
        (o.offeredDriverId != null && o.offeredDriverId!.isNotEmpty);
  }

  static bool _isActiveDelivery(Order o) {
    if (o.status == OrderStatus.onTheWay) return true;
    final phase = o.deliveryPhase ?? '';
    return phase == 'accepted' ||
        phase == 'picked_up' ||
        phase == 'in_transit';
  }

  static double? _avg(List<double> samples) {
    if (samples.isEmpty) return null;
    return samples.reduce((a, b) => a + b) / samples.length;
  }

  static List<DriverWatchdogEntry> computeWatchdog({
    required List<Order> orders,
    required List<AppUser> drivers,
    String? governorateFilter,
  }) {
    final now = DateTime.now();
    var filtered = orders;
    if (governorateFilter != null && governorateFilter.isNotEmpty) {
      filtered = orders.where((o) => o.governorate == governorateFilter).toList();
    }

    final driverById = {for (final d in drivers) d.uid: d};
    final entries = <DriverWatchdogEntry>[];

    for (final order in filtered) {
      if (order.deliveryId == null || order.deliveryId!.isEmpty) continue;
      if (order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled) {
        continue;
      }
      final phase = order.deliveryPhase ?? '';
      if (phase == 'delivered' || phase == 'cancelled') continue;

      final driver = driverById[order.deliveryId!];
      if (driver == null) continue;

      final hb = driver.heartbeatAt;
      final loc = driver.locationUpdatedAt;
      DateTime? last;
      if (hb != null && loc != null) {
        last = hb.isAfter(loc) ? hb : loc;
      } else {
        last = hb ?? loc;
      }
      if (last == null) continue;

      final idleMin = now.difference(last).inMinutes;
      if (idleMin < 5) continue;

      final severity = order.watchdogCriticalAt != null || idleMin >= 10
          ? OpsWarningSeverity.critical
          : OpsWarningSeverity.warning;

      entries.add(
        DriverWatchdogEntry(
          driverId: driver.uid,
          driverName: driver.name.isEmpty ? 'مندوب' : driver.name,
          orderId: order.id,
          storeName: order.storeName,
          idleMinutes: idleMin,
          severity: severity,
        ),
      );
    }

    entries.sort((a, b) => b.idleMinutes.compareTo(a.idleMinutes));
    return entries;
  }
}
