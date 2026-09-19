/// مفتاح Dart الاختياري (`--dart-define`) — المفتاح الأصلي للخريطة
/// يُحقَن في AndroidManifest و iOS عبر ملفات محلية (غير مرفوعة لـ Git).
abstract final class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// true فقط عند تمرير dart-define (للتلميحات في الواجهة).
  static bool get isConfigured => apiKey.isNotEmpty;
}
