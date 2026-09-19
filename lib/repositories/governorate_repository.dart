import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/models/store.dart';

class GovernorateRepository {
  GovernorateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.governorates);

  Stream<List<Governorate>> watchAll() {
    return _collection.snapshots().map((snap) {
      if (snap.docs.isEmpty) return EgyptGovernorates.all;
      final list = snap.docs.map(Governorate.fromFirestore).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Stream<List<Governorate>> watchAvailable() {
    return watchAll().map((list) {
      final available = list.where((g) => g.isAvailable).toList();
      return _uniqueById(available);
    });
  }

  static List<Governorate> _uniqueById(List<Governorate> input) {
    final seen = <String>{};
    final out = <Governorate>[];
    for (final g in input) {
      if (seen.add(g.id)) out.add(g);
    }
    return out;
  }

  Future<void> upsert(Governorate governorate) {
    return _collection
        .doc(governorate.id)
        .set(governorate.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setAvailability(String id, bool isAvailable) {
    return _collection.doc(id).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) {
    return _collection.doc(id).delete();
  }

  Future<void> createWithDefaults(Governorate governorate) async {
    await upsert(governorate);
  }

  /// مزامنة المحافظات الثابتة إلى Firestore (مرة واحدة).
  Future<void> seedFromStaticIfEmpty() async {
    final snap = await _collection.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (var i = 0; i < EgyptGovernorates.all.length; i++) {
      final g = EgyptGovernorates.all[i];
      final ref = _collection.doc(g.id);
      batch.set(ref, {
        'name': g.name,
        'isAvailable': g.isAvailable,
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
