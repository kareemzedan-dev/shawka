/// سياق جغرافي للمستخدم — يفصل App Access عن Delivery Serviceability.
enum UserGeoContext {
  /// داخل مصر ومحافظة مدعومة (توصيل محلي متاح حسب القواعد الحالية).
  egyptSupported,

  /// داخل مصر لكن المحافظة/المنطقة غير مدعومة حالياً للتوصيل.
  /// App Access: مسموح بالتصفح. Delivery: يُرفض عند الطلب إن لم يوجد عنوان مدعوم.
  egyptUnsupported,

  /// خارج مصر بشكل موثوق.
  outsideEgypt,

  /// تعذّر تحديد الدولة بثقة.
  unknown,
}

/// مدخلات خالصة لحل السياق الجغرافي (قابلة للاختبار بدون Flutter).
class GeoResolutionInput {
  const GeoResolutionInput({
    this.countryCode = '',
    this.hasCoordinates = false,
    this.coordinatesInEgyptBounds = false,
    this.matchedEgyptianGovernorate = false,
    this.matchedGovernorateAvailable = false,
  });

  /// ISO 3166-1 alpha-2 إن وُجد (مثال: EG, SA, US).
  final String countryCode;
  final bool hasCoordinates;
  final bool coordinatesInEgyptBounds;
  final bool matchedEgyptianGovernorate;
  final bool matchedGovernorateAvailable;
}

/// سياسة الوصول الجغرافي — Source of Truth لقواعد App Access.
abstract final class GeoAccessPolicy {
  static const egyptCountryCode = 'EG';

  /// حدود تقريبية لمصر — متوافقة مع فحوصات العنوان الحالية في التطبيق.
  static bool isInsideEgyptBounds(double lat, double lng) =>
      lat >= 21.5 && lat <= 31.8 && lng >= 24.5 && lng <= 37.0;

  static String normalizeCountryCode(String? raw) {
    final code = (raw ?? '').trim().toUpperCase();
    if (code.length == 2) return code;
    // geojs أحياناً يعيد اسم الدولة بدل الرمز.
    if (code == 'EGYPT' || code == 'EGY') return egyptCountryCode;
    return code;
  }

  static UserGeoContext resolve(GeoResolutionInput input) {
    final code = normalizeCountryCode(input.countryCode);

    // رمز دولة صريح غير مصر → خارج مصر.
    if (code.isNotEmpty && code != egyptCountryCode) {
      return UserGeoContext.outsideEgypt;
    }

    if (input.matchedEgyptianGovernorate) {
      return input.matchedGovernorateAvailable
          ? UserGeoContext.egyptSupported
          : UserGeoContext.egyptUnsupported;
    }

    if (code == egyptCountryCode) {
      return UserGeoContext.egyptUnsupported;
    }

    if (input.hasCoordinates) {
      if (input.coordinatesInEgyptBounds) {
        return UserGeoContext.egyptUnsupported;
      }
      return UserGeoContext.outsideEgypt;
    }

    return UserGeoContext.unknown;
  }

  /// لا يوجد Geo Context يمنع فتح التطبيق أو تصفحه.
  /// Delivery Serviceability تُفحص عند Checkout / Cloud Functions فقط.
  static bool blocksAppAccess(UserGeoContext context) => false;

  /// هل يوجد توصيل محلي نشط حسب سياق الموقع (وليس صلاحية فتح التطبيق).
  static bool hasActiveLocalDelivery(UserGeoContext context) =>
      context == UserGeoContext.egyptSupported;

  /// تصفح الكتالوج بمحافظة افتراضية مدعومة عندما لا يوجد نطاق توصيل محلي فعّال.
  static bool usesBrowsingFallback(UserGeoContext context) =>
      !hasActiveLocalDelivery(context);

  static bool allowsAppBrowsing(UserGeoContext context) => true;
}
