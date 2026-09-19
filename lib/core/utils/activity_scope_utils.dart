/// نطاق الظهور حسب نشاط العميل (كافيه / مطعم / …).
///
/// [activityTypeIds] فارغ أو غير موجود = يظهر لكل الأنشطة (توافق خلفي).
abstract final class ActivityScopeUtils {
  static List<String> readIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  /// هل يظهر المحتوى لنشاط العميل؟
  static bool matches({
    required List<String> activityTypeIds,
    required String customerActivityTypeId,
  }) {
    if (activityTypeIds.isEmpty) return true;
    final id = customerActivityTypeId.trim();
    if (id.isEmpty) return true;
    return activityTypeIds.contains(id);
  }

  /// تعيين المنتج يتجاوز المتجر. فارغ = يتبع أنشطة المتجر.
  static List<String> effectiveProductActivityIds({
    required List<String> productActivityTypeIds,
    required List<String> storeActivityTypeIds,
  }) {
    if (productActivityTypeIds.isNotEmpty) return productActivityTypeIds;
    return storeActivityTypeIds;
  }

  static bool productMatches({
    required List<String> productActivityTypeIds,
    required List<String> storeActivityTypeIds,
    required String customerActivityTypeId,
  }) {
    return matches(
      activityTypeIds: effectiveProductActivityIds(
        productActivityTypeIds: productActivityTypeIds,
        storeActivityTypeIds: storeActivityTypeIds,
      ),
      customerActivityTypeId: customerActivityTypeId,
    );
  }

  /// المتجر يظهر إن كان مربوطاً بالنشاط، أو فيه منتج مستقل يستهدف النشاط.
  static bool storeVisibleInActivity({
    required List<String> storeActivityTypeIds,
    required List<String> productActivityTypeIds,
    required String customerActivityTypeId,
  }) {
    if (matches(
      activityTypeIds: storeActivityTypeIds,
      customerActivityTypeId: customerActivityTypeId,
    )) {
      return true;
    }
    final id = customerActivityTypeId.trim();
    if (id.isEmpty) return true;
    return productActivityTypeIds.contains(id);
  }

  static List<T> filterByActivity<T>(
    Iterable<T> items, {
    required String customerActivityTypeId,
    required List<String> Function(T item) idsOf,
  }) {
    final id = customerActivityTypeId.trim();
    if (id.isEmpty) return items.toList(growable: false);
    return items
        .where((item) => matches(
              activityTypeIds: idsOf(item),
              customerActivityTypeId: id,
            ))
        .toList(growable: false);
  }

  static String summaryLabel(List<String> ids, Map<String, String> namesById) {
    if (ids.isEmpty) return 'كل الأنشطة';
    final labels = ids
        .map((id) => namesById[id] ?? id)
        .where((n) => n.isNotEmpty)
        .toList();
    if (labels.isEmpty) return 'كل الأنشطة';
    if (labels.length <= 2) return labels.join(' · ');
    return '${labels.take(2).join(' · ')} +${labels.length - 2}';
  }
}
