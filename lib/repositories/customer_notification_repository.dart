import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/models/app_notification.dart';

class CustomerNotificationRepository {
  CustomerNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Stream<List<AppNotification>> watch(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<void> persist({
    required String uid,
    required String title,
    required String body,
    String? type,
    String? deepLink,
    String? deepLinkId,
    String? campaignId,
    String? orderId,
  }) async {
    await _col(uid).add({
      'title': title,
      'body': body,
      'type': type ?? 'general',
      if (deepLink != null && deepLink.isNotEmpty) 'deepLink': deepLink,
      'deepLinkId': deepLinkId ?? orderId,
      if (campaignId != null) 'campaignId': campaignId,
      if (orderId != null) 'orderId': orderId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String uid, String id) {
    return _col(uid).doc(id).update({'isRead': true});
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _col(uid).where('isRead', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    // Firestore batch limit = 500
    for (var i = 0; i < snap.docs.length; i += 450) {
      final chunk = snap.docs.skip(i).take(450);
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  AppNotification _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type = (data['type'] as String? ?? 'general').trim();
    final deepLinkId = (data['deepLinkId'] as String? ??
            data['orderId'] as String? ??
            '')
        .trim();
    var deepLink = (data['deepLink'] as String? ?? '').trim();
    if (deepLink.isEmpty && type == 'order_status') {
      deepLink = 'order';
    }
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      type: type.isEmpty ? 'general' : type,
      deepLink: deepLink,
      deepLinkId: deepLinkId,
    );
  }
}
