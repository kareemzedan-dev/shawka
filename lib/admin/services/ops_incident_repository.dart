import 'package:cloud_firestore/cloud_firestore.dart';

class OpsIncident {
  const OpsIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.resolutionStatus,
    required this.createdAt,
    this.orderId,
    this.driverId,
  });

  final String id;
  final String type;
  final String severity;
  final String message;
  final String resolutionStatus;
  final DateTime? createdAt;
  final String? orderId;
  final String? driverId;

  factory OpsIncident.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return OpsIncident(
      id: doc.id,
      type: data['type'] as String? ?? '',
      severity: data['severity'] as String? ?? 'warning',
      message: data['message'] as String? ?? '',
      resolutionStatus: data['resolutionStatus'] as String? ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      orderId: data['orderId'] as String?,
      driverId: data['driverId'] as String?,
    );
  }
}

class OpsIncidentRepository {
  OpsIncidentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<OpsIncident>> watchRecent({int limit = 50}) {
    return _firestore
        .collection('ops_incidents')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(OpsIncident.fromFirestore).toList());
  }

  Future<void> markResolved(String id) {
    return _firestore.collection('ops_incidents').doc(id).update({
      'resolutionStatus': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
