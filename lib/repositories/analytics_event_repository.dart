import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/analytics_event.dart';

class AnalyticsEventRepository {
  AnalyticsEventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.analyticsEvents);

  Stream<List<AnalyticsEvent>> watchRecent({int limit = 200}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AnalyticsEvent.fromFirestore).toList());
  }

  Stream<List<AnalyticsEvent>> watchByUser(String userId, {int limit = 100}) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AnalyticsEvent.fromFirestore).toList());
  }

  Future<void> track(AnalyticsEvent event) {
    final ref = _collection.doc();
    return ref.set(event.toFirestore());
  }
}
