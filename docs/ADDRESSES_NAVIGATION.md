# العناوين والملاحة — Shawka

## Google Cloud Console

فعّل على **نفس مفاتيح الخرائط** (أو مفاتيح REST منفصلة مقيّدة):

| API | الاستخدام |
|-----|-----------|
| Maps SDK for Android / iOS | عرض الخريطة |
| **Places API** | Autocomplete + تفاصيل المكان |
| **Directions API** | مسارات على الشوارع + ETA + المسافة |
| **Geocoding API** | موقعي الحالي → عنوان |

قيود مقترحة:

- Android: package + SHA-1
- iOS: Bundle ID
- REST: قيّد بـ Android/iOS app + IP إن لزم

## إعداد المفاتيح محلياً

```powershell
$env:GOOGLE_MAPS_API_KEY_ANDROID = "YOUR_ANDROID_KEY"
$env:GOOGLE_MAPS_API_KEY_IOS = "YOUR_IOS_KEY"
.\scripts\configure-google-maps.ps1
flutter pub get
```

ينشئ السكربت:

- `android/local.properties`
- `ios/Flutter/Secrets.xcconfig`
- `assets/secrets/maps_keys.json` (لـ Places/Directions من Flutter)

## الميزات

- بحث Places مثل Google Maps
- 📍 موقعي الحالي + Reverse Geocoding
- حفظ المنزل / العمل / عنوان آخر في `users/{uid}/saved_addresses`
- مسارات Directions (ليست خطاً مستقيماً)
- ETA والمسافة من Directions
- رسوم توصيل حسب **مسافة الطريق**
- تتبع: متجر → مندوب → عميل
- تحكم الخريطة: تكبير/تصغير، إعادة التمركز، متابعة المندوب

## حقول الطلب الجديدة

`addressLat`, `addressLng`, `addressPlaceId`, `addressFormatted`
