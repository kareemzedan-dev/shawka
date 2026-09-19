import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';

/// أرشفة روابط الصور القديمة عند الاستبدال — للمراجعة والاسترجاع.
class ImageArchiveService {
  ImageArchiveService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.imageArchives);

  Future<void> archiveIfNeeded({
    required String entityType,
    required String entityId,
    required String field,
    String? imageUrl,
    String? thumbUrl,
    String? archivedBy,
  }) async {
    if ((imageUrl == null || imageUrl.isEmpty) &&
        (thumbUrl == null || thumbUrl.isEmpty)) {
      return;
    }

    await _collection.add({
      'entityType': entityType,
      'entityId': entityId,
      'field': field,
      'imageUrl': imageUrl ?? '',
      'thumbUrl': thumbUrl ?? '',
      'archivedBy': archivedBy ?? '',
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ImageArchiveEntry>> watchByEntity({
    required String entityType,
    required String entityId,
    int limit = 20,
  }) {
    return _collection
        .where('entityType', isEqualTo: entityType)
        .where('entityId', isEqualTo: entityId)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(ImageArchiveEntry.fromFirestore).toList();
          list.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
          return list;
        });
  }
}

class ImageArchiveEntry {
  const ImageArchiveEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.imageUrl,
    required this.thumbUrl,
    required this.archivedAt,
    this.archivedBy = '',
  });

  final String id;
  final String entityType;
  final String entityId;
  final String field;
  final String imageUrl;
  final String thumbUrl;
  final DateTime archivedAt;
  final String archivedBy;

  factory ImageArchiveEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ImageArchiveEntry(
      id: doc.id,
      entityType: data['entityType'] as String? ?? '',
      entityId: data['entityId'] as String? ?? '',
      field: data['field'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      thumbUrl: data['thumbUrl'] as String? ?? '',
      archivedBy: data['archivedBy'] as String? ?? '',
      archivedAt:
          (data['archivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
