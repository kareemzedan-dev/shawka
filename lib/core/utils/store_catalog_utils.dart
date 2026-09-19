import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';

abstract final class StoreCatalogUtils {
  static List<StoreCategoryDef> roots(List<StoreCategoryDef> all) {
    final list = all.where((c) => c.isRoot).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static List<StoreCategoryDef> childrenOf(
    List<StoreCategoryDef> all,
    String parentId,
  ) {
    final list = all.where((c) => c.parentId == parentId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static bool hasChildren(List<StoreCategoryDef> all, String categoryId) =>
      all.any((c) => c.parentId == categoryId);

  static StoreCategoryDef? byId(List<StoreCategoryDef> all, String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// أسلاف التصنيف من الجذر حتى الأب المباشر.
  static List<StoreCategoryDef> ancestorsOf(
    List<StoreCategoryDef> all,
    StoreCategoryDef node,
  ) {
    final result = <StoreCategoryDef>[];
    var parentId = node.parentId;
    final guard = <String>{};
    while (parentId.isNotEmpty && guard.add(parentId)) {
      final parent = byId(all, parentId);
      if (parent == null) break;
      result.insert(0, parent);
      parentId = parent.parentId;
    }
    return result;
  }

  /// مسار التنقل: الأسلاف + العقدة الحالية.
  static List<StoreCategoryDef> breadcrumb(
    List<StoreCategoryDef> all,
    StoreCategoryDef node,
  ) =>
      [...ancestorsOf(all, node), node];

  /// كل الأبناء والأحفاد تحت عقدة.
  static Set<String> descendantIds(
    List<StoreCategoryDef> all,
    String categoryId,
  ) {
    final ids = <String>{};
    void walk(String parentId) {
      for (final child in childrenOf(all, parentId)) {
        if (ids.add(child.id)) walk(child.id);
      }
    }

    walk(categoryId);
    return ids;
  }

  /// يمنع اختيار عقدة كأب لنفسها أو لأحد أحفادها.
  static bool canBeParent({
    required List<StoreCategoryDef> all,
    required String categoryId,
    required String candidateParentId,
  }) {
    if (candidateParentId.isEmpty) return true;
    if (candidateParentId == categoryId) return false;
    return !descendantIds(all, categoryId).contains(candidateParentId);
  }

  /// تسمية بادئة للعرض في القوائم (—— اسم).
  static String indentedLabel(StoreCategoryDef cat, {int indentSize = 2}) {
    if (cat.depth <= 0) return cat.name;
    return '${'— ' * cat.depth}${cat.name}';
  }

  static List<StoreCategoryDef> flattenTree(List<StoreCategoryDef> all) {
    final result = <StoreCategoryDef>[];
    void walk(String parentId) {
      for (final child in childrenOf(all, parentId)) {
        result.add(child);
        walk(child.id);
      }
    }

    for (final root in roots(all)) {
      result.add(root);
      walk(root.id);
    }
    // أي عقد يتيمة (أب مفقود) تُلحق في النهاية.
    final seen = result.map((e) => e.id).toSet();
    for (final c in all) {
      if (seen.add(c.id)) result.add(c);
    }
    return result;
  }

  static List<Store> filterStores(
    List<Store> stores, {
    String? governorate,
    String? categoryId,
    String? activityTypeId,
    String? zoneId,
  }) {
    var result = stores;
    if (governorate != null && governorate.isNotEmpty) {
      result = result.where((s) => s.governorate == governorate).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((s) => matchesCategory(s, categoryId)).toList();
    }
    final activity = activityTypeId?.trim() ?? '';
    if (activity.isNotEmpty) {
      result = result
          .where(
            (s) => ActivityScopeUtils.storeVisibleInActivity(
              storeActivityTypeIds: s.activityTypeIds,
              productActivityTypeIds: s.productActivityTypeIds,
              customerActivityTypeId: activity,
            ),
          )
          .toList();
    }
    final zone = zoneId?.trim() ?? '';
    if (zone.isNotEmpty) {
      result = result
          .where((s) => s.zoneId.trim().isEmpty || s.zoneId == zone)
          .toList();
    }
    return result;
  }

  static List<StoreCategoryDef> filterCategories(
    List<StoreCategoryDef> categories, {
    String? activityTypeId,
  }) {
    final activity = activityTypeId?.trim() ?? '';
    if (activity.isEmpty) return categories;
    return categories
        .where(
          (c) => ActivityScopeUtils.matches(
            activityTypeIds: c.activityTypeIds,
            customerActivityTypeId: activity,
          ),
        )
        .toList();
  }

  /// يطابق إن كان المتجر مربوطاً بهذا التصنيف (أو categoryId القديم).
  static bool matchesCategory(Store store, String categoryId) {
    if (categoryId.isEmpty) return true;
    if (store.categoryIds.contains(categoryId)) return true;
    if (store.categoryId == categoryId) return true;
    final suffix = categoryId.contains('_')
        ? categoryId.split('_').last
        : categoryId;
    return store.categoryId == suffix;
  }

  /// يطابق التصنيف أو أي فرع تحته (مفيد لفلترة الجذور / لوحة التحكم).
  static bool matchesCategoryInSubtree(
    Store store,
    String categoryId,
    List<StoreCategoryDef> all,
  ) {
    if (matchesCategory(store, categoryId)) return true;
    return descendantIds(all, categoryId)
        .any((id) => matchesCategory(store, id));
  }

  /// جذور الصفحة الرئيسية فقط + عدّ المتاجر المرتبطة مباشرة أو عبر الفروع.
  static List<StoreCategoryEntry> categoryEntries(
    List<Store> stores,
    List<StoreCategoryDef> definitions, {
    bool rootsOnly = true,
    String? activityTypeId,
  }) {
    final scopedDefs = filterCategories(
      definitions,
      activityTypeId: activityTypeId,
    );
    final defs = rootsOnly ? roots(scopedDefs) : scopedDefs;
    return defs
        .map(
          (def) {
            final subtree = {def.id, ...descendantIds(definitions, def.id)};
            final count = stores
                .where(
                  (s) => subtree.any((id) => matchesCategory(s, id)),
                )
                .length;
            return StoreCategoryEntry(definition: def, storeCount: count);
          },
        )
        .where((e) => e.storeCount > 0 || e.definition.isActive)
        .toList();
  }
}