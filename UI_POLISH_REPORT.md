# Shawka — UI Polish Report

**Date:** 2026-06-08  
**Scope:** Notifications · Search · Favorites (UI/UX only)

---

## Design tokens

| Token | Value |
|-------|--------|
| Primary Orange | `#FF7A00` |
| Dark Navy | `#0B1F3A` |
| Background | `#F6F7FB` |
| Success | `#22C55E` |
| Warning | `#F59E0B` |
| Radius | 12 / 16 / 24 |
| Spacing | 8 / 12 / 16 / 24 |
| Typography | Cairo (Google Fonts) |

**File:** `lib/core/theme/ui_polish_tokens.dart`

---

## 1. الإشعارات (`notifications_screen.dart`)

| Before | After |
|--------|--------|
| قائمة بسيطة بكروت مسطحة | Header مع badge غير مقروء + فلتر + «تحديد الكل كمقروء» |
| بدون تصنيف | Tabs: الكل · الطلبات · العروض · النظام (فلترة UI من النص) |
| كارت واحد للجميع | أيقونة/لون حسب النوع (طلبات=أخضر، عروض=برتقالي، نظام=أزرق) |
| بدون حركة | Staggered fade + slide |
| بدون refresh | Pull-to-refresh |
| Empty state أساسي | Empty state محسّن + CTA |
| — | Promo banner أسفل القائمة |

**Widgets:** `polished_notification_card.dart`, `notification_category.dart`

---

## 2. البحث (`search_screen.dart`)

| Before | After |
|--------|--------|
| Header بسيط | Navy gradient header + search field premium + mic placeholder + filter |
| فلاتر فقط | اقتراحات دائرية (بيتزا، برجر، كشري، شاورما، حلويات) |
| نتائج StoreCard عامة | `PolishedSearchResultTile` — صورة، تقييم، ETA، توصيل، حالة |
| CircularProgressIndicator | Skeleton shimmer loading |
| فارغ = لا نتائج فقط | حالة اكتشاف: «الأكثر بحثاً» + «مقترحة بالقرب منك» |
| — | Promo banner برتقالي |
| — | Staggered animations على النتائج |

**Widgets:** `polished_search_widgets.dart`, `polish_skeleton.dart`

---

## 3. المفضلة (`favorites_tab.dart`)

| Before | After |
|--------|--------|
| TabPageLayout عام | Header مخصص مع أيقونة قلب + عدد المحفوظ |
| StoreCard قياسي | `PolishedFavoriteCard` — صورة كبيرة، gradient، badges |
| إزالة بدون تراجع | Undo SnackBar عند الإزالة |
| قائمة مسطحة | بطاقة Featured أولاً + «الأكثر طلباً» + باقي المفضلة |
| بدون refresh | Pull-to-refresh |
| Empty state أساسي | Empty state محفوظ من النظام الموحد |

**Widgets:** `polished_favorites_widgets.dart`

---

## Screenshots

| Screen | Before | After |
|--------|--------|--------|
| Notifications | _(capture from pre-polish branch)_ | Run app → الإشعارات |
| Search | _(capture from pre-polish branch)_ | Run app → البحث |
| Favorites | _(capture from pre-polish branch)_ | Run app → المفضلة |

> **ملاحظة:** لالتقاط Screenshots فعلية: `flutter run` ثم التنقل للشاشات الثلاث. يمكن حفظها في `docs/ui-polish/screenshots/`.

---

## ما لم يُغيّر (حسب القيود)

- `NotificationService`, `FavoritesService`, `CatalogService`
- Repositories / Firestore / Cubits
- Routing / Navigation
- `AppNotification` model (تصنيف Tabs من title/body في UI فقط)

---

## الملفات الجديدة

```
lib/core/theme/ui_polish_tokens.dart
lib/screens/home/widgets/polish/
  notification_category.dart
  polished_notification_card.dart
  polished_search_widgets.dart
  polished_favorites_widgets.dart
  polish_skeleton.dart
```

## الملفات المعدّلة

```
lib/screens/home/notifications_screen.dart
lib/screens/home/search_screen.dart
lib/screens/home/tabs/favorites_tab.dart
```

---

## Known issues

1. **Voice search** — أيقونة الميكروفون placeholder فقط (لا backend).
2. **Filter button** — أيقونة الفلتر في الإشعارات/البحث بدون sheet بعد (UI hook جاهز).
3. **Notification tabs** — التصنيف heuristic من النص وليس حقل `type` (لتجنب تعديل Model).
