/// أدوات نصوص CMS النقية — بدون Firebase حتى تُختبر Offline.
library;

/// يستبدل `{name}` و`{city}` و`{time}` داخل قالب CMS.
String interpolateCmsTemplate(
  String template, {
  String? name,
  String? city,
  String? time,
}) {
  return template
      .replaceAll('{name}', name ?? '')
      .replaceAll('{city}', city ?? '')
      .replaceAll('{time}', time ?? '');
}

/// يحوّل قيمة CMS مفصولة بـ `|` إلى قائمة نظيفة، أو يرجع [fallback].
List<String> parseCmsPipeList(
  String raw, {
  List<String> fallback = const [],
}) {
  final values = raw
      .split('|')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  return values.isEmpty ? fallback : values;
}
