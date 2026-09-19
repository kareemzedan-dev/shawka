# Shawka Web Experience — Premium Production Platform

## Overview

نسخة ويب Premium من Shawka — بيانات حية 100% من Firestore (بدون Mock على الويب).

**لا يوجد checkout فعلي** — السلة وهمية + بوابة تحويل احترافية للتطبيق.

## Premium Features (v2)

- **Hero** — خلفية متحركة، شعار، إحصائيات حية (متاجر/منتجات/طلبات من `app_settings`)
- **PromoCarousel** — بانرات Firebase فقط عبر `WebPromoService`
- **Smart Search** — `/g/:govId/search` — متاجر + منتجات + تصنيفات
- **أقسام الرئيسية** — نفس منطق الموبايل (مميز، ترند، عروض، تقييم، سرعة…)
- **WebPremiumStoreCard** — gradient، badges، hover، حالة المتجر
- **صفحة متجر** — cover، logo، أوقات عمل، بحث منتجات، بطاقات premium
- **Governorates** — Firestore حي عبر `AppConfigService`
- **CMS** — نصوص الترحيب والبحث من `CmsTextService`

## Architecture

| Layer | Path |
|-------|------|
| Bootstrap | `lib/web/bootstrap/web_bootstrap.dart` |
| Router (GoRouter) | `lib/web/router/web_router.dart` |
| App entry | `lib/web/web_app.dart` |
| Config | `lib/web/config/web_constants.dart` |
| Services | `lib/web/services/` |
| Screens | `lib/web/screens/` |
| Widgets | `lib/web/widgets/` |

## URL Routes (SEO)

| Route | Screen |
|-------|--------|
| `/g/:govId` | Home |
| `/g/:govId/stores` | All stores + filters |
| `/g/:govId/category/:categoryId` | Category SEO page |
| `/store/:storeId` | Store detail |
| `/store/:storeId/product/:productId` | Product detail |
| `/cart` | Ghost cart + conversion gate |

## Conversion Funnel

1. **Ghost cart** — `WebCartService` (in-memory, no Firestore orders)
2. **Checkout gate** — `showWebAppConversionModal()` on «إتمام الطلب»
3. **Smart banner** — cart items → app benefits; ≥100 EGP → first-order discount
4. **Smart popup** — 3+ store visits → favorites prompt
5. **Analytics** — `WebAnalyticsService` → existing Cloud Function pipeline

## SEO

- Static meta in `web/index.html`
- Dynamic meta via `WebSeoService` (JSON-LD, OG, Twitter, canonical)
- `web/robots.txt`, `web/sitemap.xml`
- Firebase Hosting SPA rewrites in `firebase.json`

## Deploy

```bash
flutter build web --release
firebase deploy --only hosting
```

## App Store Links

Update `WebConstants.appStoreUrl` when iOS app is live.
