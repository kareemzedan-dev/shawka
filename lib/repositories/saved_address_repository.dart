import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/delivery_address.dart';

class SavedAddressRepository {
  SavedAddressRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection(FirestorePaths.users).doc(userId).collection('saved_addresses');

  Stream<List<SavedAddress>> watch(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _col(userId).snapshots().map(
          (snap) => _sorted(
            snap.docs.map((d) => SavedAddress.fromFirestore(d.id, d.data())),
          ),
        );
  }

  Future<List<SavedAddress>> fetch(String userId) async {
    if (userId.isEmpty) return const [];
    final snap = await _col(userId).get();
    return _sorted(
      snap.docs.map((d) => SavedAddress.fromFirestore(d.id, d.data())),
    );
  }

  List<SavedAddress> _sorted(Iterable<SavedAddress> items) {
    final list = items.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.label.index.compareTo(b.label.index);
    });
    return list;
  }

  /// إنشاء عنوان جديد أو تحديث موجود. يدعم عدة عناوين لنفس التسمية.
  Future<String> save({
    required String userId,
    required SavedAddressLabel label,
    required DeliveryAddress address,
    String? addressId,
    bool setDefault = false,
  }) async {
    final data = {
      'label': label.firestoreValue,
      ...address.toFirestore(),
      'isDefault': setDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (setDefault) {
      await _clearDefault(userId);
    }

    if (addressId != null && addressId.isNotEmpty) {
      await _col(userId).doc(addressId).set(data, SetOptions(merge: true));
      return addressId;
    }

    final ref = await _col(userId).add(data);
    return ref.id;
  }

  Future<void> setDefault(String userId, String addressId) async {
    await _clearDefault(userId);
    await _col(userId).doc(addressId).set(
      {
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> delete(String userId, String addressId) async {
    await _col(userId).doc(addressId).delete();
  }

  Future<void> _clearDefault(String userId) async {
    final snap = await _col(userId).where('isDefault', isEqualTo: true).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }
}
