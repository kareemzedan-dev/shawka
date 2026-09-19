# Google Maps — Shawka

## أين يُربط المفتاح (بدون رفعه إلى Git)

يمكن استخدام **مفتاحين منفصلين** (مُفضّل): واحد لـ Android مقيّد بـ SHA-1، وواحد لـ iOS مقيّد بـ Bundle ID.

| المنصة | الملف | مفتاح الإعداد |
|--------|--------|----------------|
| Android | `android/local.properties` | `google.maps.apiKey=...` |
| Android (بديل) | `secrets.properties` في جذر المشروع | `google.maps.apiKey=...` |
| Android (بديل) | متغير بيئة `GOOGLE_MAPS_API_KEY_ANDROID` أو `GOOGLE_MAPS_API_KEY` | يُقرأ عند Gradle build |
| iOS | `ios/Flutter/Secrets.xcconfig` | `GMS_API_KEY=...` |
| iOS (بديل) | متغير بيئة `GOOGLE_MAPS_API_KEY_IOS` | عبر السكربت أدناه |
| Flutter (اختياري) | `--dart-define=GOOGLE_MAPS_API_KEY=...` | للتحقق من `GoogleMapsConfig` فقط |

سكربت سريع (PowerShell) — مفتاحان منفصلان:

```powershell
$env:GOOGLE_MAPS_API_KEY_ANDROID = "YOUR_ANDROID_KEY"
$env:GOOGLE_MAPS_API_KEY_IOS = "YOUR_IOS_KEY"
.\scripts\configure-google-maps.ps1
```

أو مفتاح واحد لكلا المنصتين:

```powershell
$env:GOOGLE_MAPS_API_KEY = "YOUR_KEY_HERE"
.\scripts\configure-google-maps.ps1
```

## تشغيل التطبيق

```bash
flutter run
```

مع dart-define (اختياري):

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

## Google Cloud Console

1. فعّل **Maps SDK for Android** و **Maps SDK for iOS**.
2. فعّل **Places API** و **Directions API** و **Geocoding API** (مطلوب لنظام العناوين).
3. راجع أيضاً `docs/ADDRESSES_NAVIGATION.md`.
3. قيّد كل مفتاح على حدة (أو مفتاحين في Console):
   - **مفتاح Android:** Maps SDK for Android فقط + package `com.xyronix.shawka` + SHA-1 debug/release.
   - **مفتاح iOS:** Maps SDK for iOS فقط + Bundle ID الخاص بالتطبيق.
4. لا تضف المفتاح في مستودع Git أو لقطات شاشة.

## SHA-1 (Android)

```bash
cd android
./gradlew signingReport
```

أضف `debug` و `release` SHA-1 في قيود المفتاح.

## الميزات في التطبيق

- تتبع الطلب: عميل، متجر، مندوب، مسار Polyline.
- GPS حي للمندوب عند `onTheWay`.
- أنماط خريطة فاتح/داكن تلقائياً.
- لوحة الأدمن: موقع المتجر + خريطة المناديب.
- `LocationService` لصلاحيات GPS ومعالجة الأخطاء.

## استكشاف الأخطاء

| العرض | السبب المحتمل |
|--------|----------------|
| خريطة رمادية | مفتاح غير مضبوط أو SDK غير مفعّل |
| `API key not valid` | قيود SHA-1 / Bundle ID خاطئة |
| Placeholder بدل الخريطة | `GoogleMapsConfig` فارغ (Dart) — المفتاح الأصلي في manifest/iOS |
