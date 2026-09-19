import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/promotion.dart';

class PromotionRepository {
  PromotionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.promotions);

  Stream<List<Promotion>> watchByGovernorate(String governorate) {
    return _collection
        .where('governorate', isEqualTo: governorate)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Promotion.fromFirestore).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Stream<List<Promotion>> watchActiveByGovernorate(String governorate) {
    return watchByGovernorate(governorate).map(
      (list) => list.where((p) => p.isValidNow).toList(),
    );
  }

  Promotion? findByCode(
    List<Promotion> promotions,
    String rawCode, {
    Set<String>? storeIdsInCart,
  }) {
    final code = rawCode.trim().toUpperCase();
    for (final promo in promotions) {
      if (promo.code != code || !promo.isValidNow) continue;
      if (promo.storeId.isNotEmpty) {
        if (storeIdsInCart == null || !storeIdsInCart.contains(promo.storeId)) {
          continue;
        }
      }
      return promo;
    }
    return null;
  }

  Future<String> create(Promotion promotion) async {
    final ref = _collection.doc();
    await ref.set(promotion.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp());
    return ref.id;
  }

  Future<void> update(Promotion promotion) {
    return _collection
        .doc(promotion.id)
        .set(promotion.toFirestore(), SetOptions(merge: true));
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  Future<void> setActive(String id, bool isActive) {
    return _collection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
