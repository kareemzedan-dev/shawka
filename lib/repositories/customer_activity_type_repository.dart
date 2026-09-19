import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/customer_activity_type.dart';

class CustomerActivityTypeRepository {
  CustomerActivityTypeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.customerActivityTypes);

  Stream<List<CustomerActivityType>> watchAll() {
    return _collection.snapshots().map((snap) {
      final list = snap.docs.map(CustomerActivityType.fromFirestore).toList();
      list.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  /// الأنواع الظاهرة للعميل أثناء التسجيل.
  Stream<List<CustomerActivityType>> watchActive() {
    return watchAll().map(
      (list) => list.where((e) => e.isActive && e.name.isNotEmpty).toList(),
    );
  }

  Future<List<CustomerActivityType>> fetchActive() async {
    final snap = await _collection.get();
    final list = snap.docs
        .map(CustomerActivityType.fromFirestore)
        .where((e) => e.isActive && e.name.isNotEmpty)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<void> upsert(CustomerActivityType type) {
    final id = type.id.trim().isEmpty ? _collection.doc().id : type.id.trim();
    return _collection.doc(id).set(type.toFirestore(), SetOptions(merge: true));
  }

  Future<String> create({
    required String name,
    String iconKey = 'store',
    int? sortOrder,
    bool isActive = true,
  }) async {
    final doc = _collection.doc();
    final order = sortOrder ?? await _nextSortOrder();
    await doc.set(
      CustomerActivityType(
        id: doc.id,
        name: name.trim(),
        iconKey: iconKey,
        sortOrder: order,
        isActive: isActive,
      ).toFirestore(),
    );
    return doc.id;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  Future<void> setActive(String id, bool isActive) {
    return _collection.doc(id).set(
      {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> batchUpdateSortOrder(List<CustomerActivityType> ordered) async {
    final batch = _firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.set(
        _collection.doc(ordered[i].id),
        {
          'sortOrder': i,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<int> _nextSortOrder() async {
    final snap = await _collection.orderBy('sortOrder', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return 0;
    final current = (snap.docs.first.data()['sortOrder'] as num?)?.toInt() ?? 0;
    return current + 1;
  }

  /// يزرع الأنواع الافتراضية مرة واحدة دون المساس بما أضافه الأدمن.
  Future<void> seedDefaultsIfNeeded() async {
    final existing = await _collection.get();
    final have = existing.docs.map((d) => d.id).toSet();
    for (final entry in CustomerActivityTypeDefaults.entries) {
      if (have.contains(entry.id)) continue;
      try {
        await _collection.doc(entry.id).set({
          ...entry.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // العميل لا يملك صلاحية الكتابة — البذور تتم من الأدمن.
      }
    }
  }
}
