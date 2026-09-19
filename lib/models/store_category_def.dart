import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/models/store.dart';

/// تصنيف شجري (رئيسي / فرعي متداخل) قابل للإدارة من لوحة التحكم لكل محافظة.
class StoreCategoryDef {
  const StoreCategoryDef({
    required this.id,
    required this.name,
    required this.governorate,
    this.parentId = '',
    this.path = '',
    this.depth = 0,
    this.imageUrl,
    this.imageThumbUrl,
    this.imageAsset,
    this.sortOrder = 0,
    this.isActive = true,
    this.priority = 0,
    this.colorArgb,
    this.activityTypeIds = const [],
  });

  final String id;
  final String name;
  final String governorate;
  /// فارغ = تصنيف رئيسي (جذر).
  final String parentId;
  /// مسار الأسلاف + الذات، مثال: `rootId/childId/leafId`.
  final String path;
  final int depth;
  final String? imageUrl;
  final String? imageThumbUrl;
  final String? imageAsset;
  final int sortOrder;
  final bool isActive;
  final int priority;
  final int? colorArgb;
  /// أنشطة الظهور (فارغ = كل الأنشطة).
  final List<String> activityTypeIds;

  bool get isRoot => parentId.trim().isEmpty;
  bool get hasNetworkImage =>
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (imageThumbUrl != null && imageThumbUrl!.trim().isNotEmpty);

  String get effectivePath => path.trim().isNotEmpty ? path.trim() : id;

  IconData get icon => storeCategoryIcon(id);

  factory StoreCategoryDef.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      StoreCategoryDef.fromMap(id: doc.id, data: doc.data() ?? const {});

  factory StoreCategoryDef.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final parentId = (data['parentId'] as String? ?? '').trim();
    final path = (data['path'] as String? ?? '').trim();
    return StoreCategoryDef(
      id: id,
      name: data['name'] as String? ?? '',
      governorate: data['governorate'] as String? ?? '',
      parentId: parentId,
      path: path.isNotEmpty ? path : id,
      depth: () {
        final raw = (data['depth'] as num?)?.toInt();
        if (raw != null) return raw;
        if (parentId.isEmpty) return 0;
        final parts = path.split('/').where((p) => p.isNotEmpty).length;
        return (parts > 0 ? parts - 1 : 1).clamp(0, 32);
      }(),
      imageUrl: normalizeStoredImageUrl(data['imageUrl'] as String?),
      imageThumbUrl: normalizeStoredImageUrl(data['imageThumbUrl'] as String?),
      imageAsset: data['imageAsset'] as String?,
      sortOrder: data['sortOrder'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      colorArgb: (data['colorArgb'] as num?)?.toInt(),
      activityTypeIds: ActivityScopeUtils.readIds(data['activityTypeIds']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'governorate': governorate,
      'parentId': parentId,
      'path': effectivePath,
      'depth': depth,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'imageAsset': imageAsset,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'priority': priority,
      if (colorArgb != null) 'colorArgb': colorArgb,
      'activityTypeIds': activityTypeIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StoreCategoryDef copyWith({
    String? name,
    String? parentId,
    String? path,
    int? depth,
    String? imageUrl,
    String? imageThumbUrl,
    String? imageAsset,
    int? sortOrder,
    bool? isActive,
    int? priority,
    int? colorArgb,
    List<String>? activityTypeIds,
  }) {
    return StoreCategoryDef(
      id: id,
      name: name ?? this.name,
      governorate: governorate,
      parentId: parentId ?? this.parentId,
      path: path ?? this.path,
      depth: depth ?? this.depth,
      imageUrl: imageUrl ?? this.imageUrl,
      imageThumbUrl: imageThumbUrl ?? this.imageThumbUrl,
      imageAsset: imageAsset ?? this.imageAsset,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      colorArgb: colorArgb ?? this.colorArgb,
      activityTypeIds: activityTypeIds ?? this.activityTypeIds,
    );
  }

  /// يبني path/depth لتصنيف جديد أو منقول تحت أب معيّن.
  static ({String path, int depth, String parentId}) hierarchyFor({
    required String id,
    StoreCategoryDef? parent,
  }) {
    if (parent == null) {
      return (path: id, depth: 0, parentId: '');
    }
    return (
      path: '${parent.effectivePath}/$id',
      depth: parent.depth + 1,
      parentId: parent.id,
    );
  }
}

class StoreCategoryEntry {
  const StoreCategoryEntry({
    required this.definition,
    required this.storeCount,
  });

  final StoreCategoryDef definition;
  final int storeCount;
}
