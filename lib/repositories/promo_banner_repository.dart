import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/models/promo_banner_record.dart';

class PromoBannerRepository {
  PromoBannerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.promoBanners);

  Stream<List<PromoBannerRecord>> watchByGovernorate(String governorate) {
    PromoBannerDebug.log(
      'Firestore.watch collection=${FirestorePaths.promoBanners} '
      'Requested Governorate: "$governorate"',
    );
    return _collection
        .where('governorate', isEqualTo: governorate)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(PromoBannerRecord.fromFirestore).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      PromoBannerDebug.log(
        'Firestore.watch docs=${snap.docs.length} parsed=${list.length} '
        'Requested Governorate: "$governorate"',
      );
      for (final r in list) {
        PromoBannerDebug.log(
          'Firestore.watch ID: ${r.id} Saved Governorate: "${r.governorate}" '
          'Equality Result: ${r.governorate == governorate} '
          'imageUrl: ${PromoBannerDebug.describeUrl(r.imageUrl)}',
        );
      }
      if (list.isEmpty) {
        PromoBannerDebug.log(
          'Firestore.watch EMPTY for Requested Governorate: "$governorate" '
          '(no docs matched — possible governorate mismatch spelling)',
        );
      }
      return list;
    });
  }

  Future<String> create(PromoBannerRecord banner) async {
    final ref = _collection.doc();
    PromoBannerDebug.log(
      'Firestore.create docId=${ref.id} '
      'Saved Governorate: "${banner.governorate}" '
      'endsAt=${banner.endsAt?.toIso8601String() ?? "null"} '
      'imageUrl=${PromoBannerDebug.describeUrl(banner.imageUrl)}',
    );
    await ref.set(banner.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp());
    PromoBannerDebug.log('Firestore.create OK id=${ref.id}');
    return ref.id;
  }

  Future<void> update(PromoBannerRecord banner) {
    PromoBannerDebug.log(
      'Firestore.update id=${banner.id} '
      'Saved Governorate: "${banner.governorate}" '
      'endsAt=${banner.endsAt?.toIso8601String() ?? "null"} '
      'imageUrl=${PromoBannerDebug.describeUrl(banner.imageUrl)}',
    );
    return _collection
        .doc(banner.id)
        .set(banner.toFirestore(), SetOptions(merge: true));
  }

  Future<void> delete(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> setActive(String id, bool isActive) {
    return _collection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> batchUpdateSortOrder(List<PromoBannerRecord> ordered) async {
    if (ordered.isEmpty) return;
    final batch = _firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_collection.doc(ordered[i].id), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
