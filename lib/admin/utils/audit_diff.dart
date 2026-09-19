/// حساب الفروقات قبل/بعد لتسجيل Audit.
class AuditFieldChange {
  const AuditFieldChange({
    required this.field,
    required this.before,
    required this.after,
  });

  final String field;
  final String before;
  final String after;

  bool get changed => before != after;
}

abstract final class AuditDiff {
  static const _skipFields = {'updatedAt', 'createdAt', 'lastActiveAt'};

  static Map<String, dynamic> snapshot(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    for (final e in data.entries) {
      if (_skipFields.contains(e.key)) continue;
      out[e.key] = _stringify(e.value);
    }
    return out;
  }

  static List<AuditFieldChange> compute({
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) {
    final b = before ?? const {};
    final a = after ?? const {};
    final keys = {...b.keys, ...a.keys}.toList()..sort();
    final changes = <AuditFieldChange>[];

    for (final key in keys) {
      if (_skipFields.contains(key)) continue;
      final bv = _stringify(b[key]);
      final av = _stringify(a[key]);
      if (bv != av) {
        changes.add(AuditFieldChange(field: key, before: bv, after: av));
      }
    }
    return changes;
  }

  static List<AuditFieldChange> fromMetadata(Map<String, dynamic> metadata) {
    final raw = metadata['changes'];
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is! Map) return null;
          return AuditFieldChange(
            field: e['field']?.toString() ?? '',
            before: e['before']?.toString() ?? '',
            after: e['after']?.toString() ?? '',
          );
        })
        .whereType<AuditFieldChange>()
        .where((c) => c.field.isNotEmpty)
        .toList();
  }

  static String _stringify(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    if (value is String) return value;
    return value.toString();
  }
}
