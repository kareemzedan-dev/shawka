import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/zone.dart';

class ZoneRepository {
  ZoneRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _zonesCollection(
    String governorateId,
  ) =>
      _firestore.collection(FirestorePaths.governorateZones(governorateId));

  Stream<List<ServiceZone>> watchAll(String governorateId) {
    return _zonesCollection(governorateId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ServiceZone.fromFirestore(doc, governorateId: governorateId))
            .toList());
  }

  Stream<List<ServiceZone>> watchActive(String governorateId) {
    return _zonesCollection(governorateId)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ServiceZone.fromFirestore(doc, governorateId: governorateId))
            .toList());
  }

  Future<void> upsert(ServiceZone zone) {
    return _zonesCollection(zone.governorateId)
        .doc(zone.id)
        .set(zone.toFirestore(), SetOptions(merge: true));
  }

  Future<void> delete(String governorateId, String zoneId) {
    return _zonesCollection(governorateId).doc(zoneId).delete();
  }

  Future<void> setActive(String governorateId, String zoneId, bool isActive) {
    return _zonesCollection(governorateId).doc(zoneId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// جلب كل المناطق النشطة عبر جميع المحافظات.
  Future<List<ServiceZone>> fetchAllActive() async {
    final snap = await _firestore
        .collectionGroup('zones')
        .where('isActive', isEqualTo: true)
        .get();

    return snap.docs.map((doc) {
      final governorateId = doc.reference.parent.parent!.id;
      return ServiceZone.fromFirestore(doc, governorateId: governorateId);
    }).toList();
  }
}
