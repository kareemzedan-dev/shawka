import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';

class ServiceAreaWaitlistRepository {
  ServiceAreaWaitlistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.serviceAreaWaitlist);

  Future<void> join({
    required String name,
    required String phone,
    required String governorate,
    String governorateId = '',
    String fcmToken = '',
  }) async {
    await _collection.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'governorate': governorate.trim(),
      if (governorateId.isNotEmpty) 'governorateId': governorateId,
      if (fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      'notified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<Map<String, int>> watchCountsByGovernorate() {
    return watchAll().map((rows) {
      final counts = <String, int>{};
      for (final row in rows) {
        final gov = row['governorate'] as String? ?? 'غير محدد';
        counts[gov] = (counts[gov] ?? 0) + 1;
      }
      return counts;
    });
  }
}
