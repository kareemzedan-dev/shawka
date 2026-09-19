import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/push_campaign.dart';

class PushCampaignRepository {
  PushCampaignRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.pushCampaigns);

  Stream<List<PushCampaign>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PushCampaign.fromFirestore).toList());
  }

  Future<String> create(PushCampaign campaign) async {
    final ref = _collection.doc();
    await ref.set(campaign.toFirestore());
    return ref.id;
  }

  Future<void> updateStatus(String id, PushCampaignStatus status) {
    return _collection.doc(id).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancel(String id) =>
      updateStatus(id, PushCampaignStatus.cancelled);
}
