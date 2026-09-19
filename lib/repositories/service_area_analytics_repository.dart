import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/utils/platform_info.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';

enum ServiceAreaEventType {
  supported,
  unsupported,
  outsideEgypt,
  unknownGeo,
  waitlistJoin,
  manualOverride,
  retryDetection,
}

class ServiceAreaAnalyticsRepository {
  ServiceAreaAnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.serviceAreaEvents);

  Future<void> log({
    required ServiceAreaEventType type,
    required String governorate,
    required bool supported,
    String governorateId = '',
    String city = '',
    String area = '',
    bool manual = false,
    String countryCode = '',
    String geoContext = '',
  }) async {
    try {
      await _collection.add({
        'type': type.name,
        'governorate': governorate,
        if (governorateId.isNotEmpty) 'governorateId': governorateId,
        'supported': supported,
        if (city.isNotEmpty) 'city': city,
        if (area.isNotEmpty) 'area': area,
        'manual': manual,
        if (countryCode.isNotEmpty) 'countryCode': countryCode,
        if (geoContext.isNotEmpty) 'geoContext': geoContext,
        'platform': platformOperatingSystem,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort analytics.
    }
  }

  Stream<ServiceAreaStats> watchStats() {
    return _collection.snapshots().map((snap) {
      var supportedUsers = 0;
      var unsupportedUsers = 0;
      final demand = <String, int>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? '';
        final gov = data['governorate'] as String? ?? '';
        final isSupported = data['supported'] as bool? ?? false;

        if (type == ServiceAreaEventType.supported.name ||
            (type == ServiceAreaEventType.manualOverride.name && isSupported)) {
          supportedUsers++;
        }
        if (type == ServiceAreaEventType.unsupported.name ||
            (type == ServiceAreaEventType.retryDetection.name &&
                !isSupported)) {
          unsupportedUsers++;
        }
        if (!isSupported && gov.isNotEmpty) {
          demand[gov] = (demand[gov] ?? 0) + 1;
        }
      }

      final topDemand = demand.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ServiceAreaStats(
        supportedDetections: supportedUsers,
        unsupportedDetections: unsupportedUsers,
        topRequestedGovernorates: topDemand.take(5).toList(),
      );
    });
  }
}

class ServiceAreaStats {
  const ServiceAreaStats({
    required this.supportedDetections,
    required this.unsupportedDetections,
    required this.topRequestedGovernorates,
  });

  final int supportedDetections;
  final int unsupportedDetections;
  final List<MapEntry<String, int>> topRequestedGovernorates;
}
