import 'package:matlobgo/models/analytics_event.dart';

class AdminFunnelStep {
  const AdminFunnelStep({
    required this.type,
    required this.label,
    required this.count,
    required this.uniqueUsers,
    required this.dropOffRate,
  });

  final AnalyticsEventType type;
  final String label;
  final int count;
  final int uniqueUsers;
  final double dropOffRate;
}

class AdminJourneyFlow {
  const AdminJourneyFlow({
    required this.fromLabel,
    required this.toLabel,
    required this.count,
    required this.widthFactor,
  });

  final String fromLabel;
  final String toLabel;
  final int count;
  final double widthFactor;
}

class AdminSessionStats {
  const AdminSessionStats({
    required this.totalSessions,
    required this.avgDurationSeconds,
    required this.avgEventsPerSession,
  });

  final int totalSessions;
  final double avgDurationSeconds;
  final double avgEventsPerSession;
}

abstract final class AdminFunnelCalculator {
  static const _funnelTypes = [
    AnalyticsEventType.storeView,
    AnalyticsEventType.productView,
    AnalyticsEventType.addToCart,
    AnalyticsEventType.checkoutStart,
    AnalyticsEventType.orderPlaced,
  ];

  static List<AdminFunnelStep> computeFunnel(List<AnalyticsEvent> events) {
    final counts = <AnalyticsEventType, int>{};
    final users = <AnalyticsEventType, Set<String>>{};

    for (final type in _funnelTypes) {
      counts[type] = 0;
      users[type] = {};
    }

    for (final e in events) {
      if (!_funnelTypes.contains(e.type)) continue;
      counts[e.type] = (counts[e.type] ?? 0) + 1;
      users[e.type]!.add(e.userId);
    }

    final steps = <AdminFunnelStep>[];
    int? prevUnique;

    for (final type in _funnelTypes) {
      final unique = users[type]!.length;
      final drop = prevUnique == null || prevUnique == 0
          ? 0.0
          : 1.0 - (unique / prevUnique);
      steps.add(
        AdminFunnelStep(
          type: type,
          label: type.label,
          count: counts[type] ?? 0,
          uniqueUsers: unique,
          dropOffRate: drop.clamp(0.0, 1.0),
        ),
      );
      prevUnique = unique;
    }
    return steps;
  }

  static List<AdminJourneyFlow> computeSankeyFlows(
    List<AnalyticsEvent> events,
  ) {
    final steps = computeFunnel(events);
    if (steps.length < 2) return const [];

    final maxCount = steps.map((s) => s.count).fold(1, (a, b) => a > b ? a : b);
    final flows = <AdminJourneyFlow>[];

    for (var i = 0; i < steps.length - 1; i++) {
      final from = steps[i];
      final to = steps[i + 1];
      final flowCount = to.count < from.count ? to.count : from.count;
      flows.add(
        AdminJourneyFlow(
          fromLabel: from.label,
          toLabel: to.label,
          count: flowCount,
          widthFactor: flowCount / maxCount,
        ),
      );
    }
    return flows;
  }

  static AdminSessionStats computeSessionStats(List<AnalyticsEvent> events) {
    final sessionEnds = events
        .where((e) => e.type == AnalyticsEventType.sessionEnd)
        .toList();
    if (sessionEnds.isEmpty) {
      return const AdminSessionStats(
        totalSessions: 0,
        avgDurationSeconds: 0,
        avgEventsPerSession: 0,
      );
    }

    var totalDuration = 0;
    var totalEvents = 0;
    for (final e in sessionEnds) {
      totalDuration +=
          (e.metadata['durationSeconds'] as num?)?.toInt() ?? 0;
      totalEvents += (e.metadata['eventCount'] as num?)?.toInt() ?? 0;
    }
    final n = sessionEnds.length;
    return AdminSessionStats(
      totalSessions: n,
      avgDurationSeconds: totalDuration / n,
      avgEventsPerSession: totalEvents / n,
    );
  }

  static Map<String, int> userFunnelProgress(List<AnalyticsEvent> events) {
    const rank = {
      AnalyticsEventType.storeView: 1,
      AnalyticsEventType.productView: 2,
      AnalyticsEventType.addToCart: 3,
      AnalyticsEventType.checkoutStart: 4,
      AnalyticsEventType.orderPlaced: 5,
    };
    var maxRank = 0;
    for (final e in events) {
      final r = rank[e.type];
      if (r != null && r > maxRank) maxRank = r;
    }
    return {'maxStep': maxRank, 'totalEvents': events.length};
  }
}
