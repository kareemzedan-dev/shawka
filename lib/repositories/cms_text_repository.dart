import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/cms_text_entry.dart';

class CmsTextRepository {
  CmsTextRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.cmsTexts);

  Stream<List<CmsTextEntry>> watchAll() {
    return _collection.snapshots().map((snap) {
      final list = snap.docs.map(CmsTextEntry.fromFirestore).toList();
      list.sort((a, b) => a.label.compareTo(b.label));
      return list;
    });
  }

  Stream<Map<String, String>> watchTextMap() {
    return watchAll().map((entries) {
      return {for (final e in entries) e.key: e.value};
    });
  }

  Future<void> upsert(CmsTextEntry entry) {
    return _collection.doc(entry.key).set(entry.toFirestore(), SetOptions(merge: true));
  }

  Future<void> seedDefaultsIfEmpty() async {
    final snap = await _collection.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    await ensureDefaultKeys();
  }

  /// يضيف المفاتيح الناقصة دون المساس بقيم موجودة (للتثبيتات القديمة).
  Future<void> ensureDefaultKeys() async {
    final existing = await _collection.get();
    final have = existing.docs.map((d) => d.id).toSet();
    for (final (key, label, value) in CmsTextDefaults.entries) {
      if (have.contains(key)) continue;
      try {
        await _collection.doc(key).set({
          'key': key,
          'label': label,
          'value': value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Web guests cannot write cms_texts; fall back to in-app defaults.
      }
    }
  }
}
