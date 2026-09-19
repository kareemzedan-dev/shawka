import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/cache/cache_policy.dart';
import 'package:matlobgo/core/cache/cached_firestore_stream.dart';
import 'package:matlobgo/core/cache/firestore_cache_store.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/data/mappers/store_category_mapper.dart';
import 'package:matlobgo/models/store_category_def.dart';

class StoreCategoryRepository {
  StoreCategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.storeCategories);

  Stream<List<StoreCategoryDef>> watchByGovernorate(String governorate) {
    final source = _collection
        .where('governorate', isEqualTo: governorate)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(StoreCategoryDef.fromFirestore).toList();
      list.sort((a, b) {
        final byDepth = a.depth.compareTo(b.depth);
        if (byDepth != 0) return byDepth;
        return a.sortOrder.compareTo(b.sortOrder);
      });
      return list;
    });

    return cachedFirestoreStream<List<StoreCategoryDef>>(
      cacheKey: CacheKeys.categories(governorate),
      policy: CachePolicy.catalog,
      source: source,
      decode: StoreCategoryMapper.fromCacheJson,
      encode: StoreCategoryMapper.toCacheJson,
    );
  }

  Stream<List<StoreCategoryDef>> watchActiveByGovernorate(String governorate) {
    return watchByGovernorate(governorate).map(
      (list) => list.where((c) => c.isActive).toList(),
    );
  }

  Future<void> upsert(StoreCategoryDef category) {
    return _collection
        .doc(category.id)
        .set(category.toFirestore(), SetOptions(merge: true));
  }

  /// إنشاء تصنيف — يمرَّر [parent] لبناء المسار الشجري تلقائياً.
  Future<String> create(
    StoreCategoryDef category, {
    StoreCategoryDef? parent,
  }) async {
    final ref = category.id.isNotEmpty
        ? _collection.doc(category.id)
        : _collection.doc();
    final id = ref.id;
    final h = StoreCategoryDef.hierarchyFor(id: id, parent: parent);
    final toSave = category.copyWith(
      parentId: h.parentId,
      path: h.path,
      depth: h.depth,
    );
    await ref.set({
      ...toSave.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
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

  Future<void> batchUpdateSortOrder(List<StoreCategoryDef> ordered) async {
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

  /// بعد نقل عقدة، يحدّث مسارات الأحفاد تحت [oldPath].
  Future<void> repathSubtree({
    required StoreCategoryDef moved,
    required List<StoreCategoryDef> all,
    required String oldPath,
  }) async {
    final batch = _firestore.batch();
    batch.set(
      _collection.doc(moved.id),
      moved.toFirestore(),
      SetOptions(merge: true),
    );
    final prefix = '$oldPath/';
    for (final node in all) {
      if (node.id == moved.id) continue;
      if (!node.effectivePath.startsWith(prefix) &&
          node.effectivePath != oldPath) {
        continue;
      }
      if (node.effectivePath == oldPath) continue;
      final suffix = node.effectivePath.substring(oldPath.length);
      final newPath = '${moved.effectivePath}$suffix';
      batch.update(_collection.doc(node.id), {
        'path': newPath,
        'depth': newPath.split('/').where((p) => p.isNotEmpty).length - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
