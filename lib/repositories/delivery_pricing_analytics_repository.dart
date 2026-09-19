import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/utils/platform_info.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';

class DeliveryPricingAnalyticsRepository {
  DeliveryPricingAnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.deliveryPricingEvents);

  Future<void> logQuote({
    required double distanceKm,
    required double fee,
    required bool isInZone,
    required int storeCount,
    String area = '',
    String governorate = '',
    String blockedStoreName = '',
    bool freeDelivery = false,
  }) async {
    try {
      await _collection.add({
        'distanceKm': distanceKm,
        'fee': fee,
        'isInZone': isInZone,
        'storeCount': storeCount,
        if (area.isNotEmpty) 'area': area,
        if (governorate.isNotEmpty) 'governorate': governorate,
        if (blockedStoreName.isNotEmpty) 'blockedStoreName': blockedStoreName,
        'freeDelivery': freeDelivery,
        'platform': platformOperatingSystem,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort analytics.
    }
  }

  Stream<DeliveryPricingStats> watchStats() {
    return _collection.snapshots().map((snap) {
      var totalDistance = 0.0;
      var totalFee = 0.0;
      var inZoneCount = 0;
      var outOfZoneCount = 0;
      final areaDemand = <String, int>{};
      final unservedAreas = <String, int>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final km = (data['distanceKm'] as num?)?.toDouble() ?? 0;
        final fee = (data['fee'] as num?)?.toDouble() ?? 0;
        final inZone = data['isInZone'] as bool? ?? true;
        final area = data['area'] as String? ?? '';
        final blocked = data['blockedStoreName'] as String? ?? '';

        if (inZone && km > 0) {
          totalDistance += km;
          totalFee += fee;
          inZoneCount++;
          if (area.isNotEmpty) {
            areaDemand[area] = (areaDemand[area] ?? 0) + 1;
          }
        } else {
          outOfZoneCount++;
          final key = area.isNotEmpty ? area : blocked;
          if (key.isNotEmpty) {
            unservedAreas[key] = (unservedAreas[key] ?? 0) + 1;
          }
        }
      }

      final topAreas = areaDemand.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topUnserved = unservedAreas.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return DeliveryPricingStats(
        averageDistanceKm:
            inZoneCount > 0 ? totalDistance / inZoneCount : 0,
        averageFee: inZoneCount > 0 ? totalFee / inZoneCount : 0,
        inZoneQuotes: inZoneCount,
        outOfZoneQuotes: outOfZoneCount,
        topAreas: topAreas.take(5).toList(),
        topUnservedAreas: topUnserved.take(5).toList(),
      );
    });
  }
}

class DeliveryPricingStats {
  const DeliveryPricingStats({
    required this.averageDistanceKm,
    required this.averageFee,
    required this.inZoneQuotes,
    required this.outOfZoneQuotes,
    required this.topAreas,
    required this.topUnservedAreas,
  });

  final double averageDistanceKm;
  final double averageFee;
  final int inZoneQuotes;
  final int outOfZoneQuotes;
  final List<MapEntry<String, int>> topAreas;
  final List<MapEntry<String, int>> topUnservedAreas;
}
