# معمارية Shawka

## نظرة عامة

منصة واحدة — **قاعدة بيانات موحدة (Firebase / Firestore)** — وعدة واجهات:

| الواجهة | النوع | الحالة |
|---------|--------|--------|
| تطبيق العميل | Flutter (Android / iOS) | موجود — `lib/main.dart` |
| تطبيق الدليفري | Flutter (Android / iOS) | مشروع منفصل لاحقاً — نفس Firebase |
| موقع العميل | Flutter Web أو Web | مشروع منفصل لاحقاً — نفس Firebase |
| لوحة التحكم | Flutter Web | موجود — `lib/main_admin.dart` |

كل التطبيقات تتصل بمشروع Firebase: **`shawka-689fa`**.

## هيكل Firestore

```
users/{uid}
  name, email, isGuest, role, createdAt
  role: customer | delivery | admin

stores/{storeId}
  name, category (restaurant|market|pharmacy), rating, deliveryMinutes,
  deliveryFee, isOpen, tags[], governorate, isFeatured, discountLabel,
  imageUrl?, description?, isActive, createdAt, updatedAt

stores/{storeId}/products/{productId}
  name, price, description?, imageUrl?, isAvailable, sortOrder,
  createdAt, updatedAt

orders/{orderId}          ← للطلبات (قادم)
governorates/{id}         ← المحافظات (قادم)
promo_banners/{id}        ← البانرات (قادم)
```

## الصلاحيات

- **عميل (`customer`)**: قراءة المتاجر النشطة ومنتجاتها، إنشاء طلبات، إدارة ملفه.
- **دليفري (`delivery`)**: قراءة الطلبات المعينة له، تحديث حالة التوصيل.
- **أدمن (`admin`)**: CRUD كامل على المتاجر والمنتجات والمحتوى من لوحة التحكم.

## الكود المشترك (حالياً في نفس المستودع)

```
lib/
  models/          ← Store, Product, AppUser, UserRole
  repositories/    ← StoreRepository, ProductRepository
  services/        ← AuthService, CatalogService
  admin/           ← لوحة التحكم فقط
  main.dart        ← تطبيق العميل
  main_admin.dart  ← لوحة التحكم
```

لاحقاً يُفضّل استخراج `models` + `repositories` + `services` إلى package مشترك وربطه بكل المشاريع.

## تشغيل لوحة التحكم

```bash
flutter run -d chrome -t lib/main_admin.dart
```

## إنشاء أول حساب أدمن

1. أنشئ مستخدماً في Firebase Authentication (بريد + كلمة مرور).
2. في Firestore → `users/{uid}` عيّن الحقل:
   ```json
   { "role": "admin", "name": "المدير", "email": "...", "isGuest": false }
   ```
3. سجّل الدخول من لوحة التحكم.

## نشر قواعد Firestore

```bash
firebase deploy --only firestore:rules,firestore:indexes
```
