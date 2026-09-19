# Reference Implementation — معايير الجودة

## Cart = Reference Implementation v1

شاشة **السلة (Cart)** معتمدة كـ **Reference Implementation v1** معماريًا ووظيفيًا.

أي شاشة جديدة يجب أن **تعيد استخدام أنماط Cart** — وليس بناء نظام جديد من الصفر.

### ما الذي يعنيه «مرجع»؟

| المحور | المعيار المستمد من Cart |
|---|---|
| Architecture | UI رفيع → Controller → Repository → Services / Cloud Functions |
| Component Structure | شاشة + `widgets/` منفصلة |
| Repositories | لا يستدعي الـ UI الـ Service مباشرة لتدفقات الشاشة |
| State Management | `ChangeNotifier` واضح |
| Performance | Listeners مضبوطة + Profile في Sprint 2 |
| Accessibility | Semantics + لمس ≥ 48dp + WCAG AA |
| Testing | عقود في Sprint 1؛ Golden / Profile في Sprint 2 |
| Motion | tokens موحّدة |
| Production Quality | لا أسعار مالية موثوقة من العميل |

---

## Checkout = Reference Implementation v2 (مكتملة)

شاشة **إتمام الطلب (Checkout)** أكملت Sprint 1 + Sprint 2 وتُعتمد **Reference Implementation v2**:

- `lib/screens/home/checkout/**` — UI رفيع → `CheckoutController` → `CheckoutRepository`.
- التسعير النهائي من Cloud Function (لا حساب موثوق على العميل).
- Golden: `test/golden/checkout_golden_test.dart` + helpers.
- Profile: `lib/debug/checkout_profile_app.dart`.

---

## Product Details = Reference Implementation v3 (مكتملة)

شاشة **تفاصيل المنتج (Product Details)** أكملت Sprint 1 + Sprint 2 وتُعتمد **Reference Implementation v3**:

- **Architecture:** `lib/screens/home/product/**` — تكوين رفيع → `ProductDetailsController` → `ProductDetailsRepository`.
- **Tokens / Tests:** `product_tokens.dart`، contract + golden + a11y، `lib/debug/product_profile_app.dart`.

---

## Orders = Reference Implementation v4 (مكتملة)

شاشة **طلباتي (Orders)** أكملت Sprint 1 + Sprint 2 وتُعتمد **Reference Implementation v4**:

- **Architecture:** `lib/screens/home/orders/**` — تكوين رفيع (`orders_tab.dart`) → `OrdersController` → `OrdersRepository` → `OrderService` / CF. لا Firestore داخل الودجات.
- **Realtime:** بث `watchByCustomer` مُصفّى بـ `customerId == auth.uid` (قواعد Firestore ترفض قراءة طلبات الغير).
- **UI SSOT:** رأس + شرائح نشطة/مكتملة/ملغية بأعداد لحظية، بطاقة طلب بخط زمني أفقي 4 خطوات، بطاقة ETA، معاينة منتجات `+N`، زر «تتبع الطلب مباشرة»، تفاصيل قابلة للتوسيع (lazy)، إجراءات مكتملة (إعادة طلب / تقييم مندوب).
- **Reuse:** `openOrderTracking`، `ReorderService`، `OrderCancelService`، `showDriverRatingSheet`، `CatalogNetworkImage`، `CartTokens` عبر `orders_tokens.dart`.
- **A11y:** Semantics على التتبّع/الأقسام، مساحات لمس ≥ 48dp، أسعار بـ `accentText` (WCAG AA).
- **Analytics:** `ordersOpen`، `orderExpand`، `orderTrack`، `orderReorder`، `orderRate`، `orderCancel`، `orderInvoice`.
- **Tests / Preview:** `test/orders_contract_test.dart`، `test/golden/orders_golden_test.dart` + helpers، `test/orders_a11y_contrast_test.dart`، `lib/debug/orders_preview.dart`.

---

## Search = Reference Implementation v5 (مكتملة)

شاشة **البحث (Search)** أكملت Sprint 1 + Sprint 2 وتُعتمد **Reference Implementation v5**:

- **Architecture:** `lib/screens/home/search/**` — تكوين رفيع (`search_screen.dart`) → `SearchScreenController` → `SearchRepository` → `CatalogService` / `CmsTextService` / `FavoritesService` / prefs مرتبطة بالمستخدم. لا منطق أعمال داخل الودجات. Barrel: `lib/screens/home/search_screen.dart`.
- **UI SSOT:** هيرو (رجوع / عنوان / فلتر / بحث pill / ميكروفون)، دوّارة تصنيفات، شرائح فلتر، سجل بحث صفوف، الأكثر بحثاً، بطاقات مطاعم مقترحة (صورة + شارات + مفضلة + مفتوح + تقييم + وقت/رسوم توصيل).
- **Search UX:** Debounce 300ms، ترتيب بالتطابق (اسم/وسوم/تصنيف/كلمات/منتجات)، pagination كسول، فلاتر متقدّمة (مفتوح / مجاني / عروض)، سجل حديث مرتبط بـ `uid`.
- **Reuse:** `CatalogFavoriteButton`، `CatalogNetworkImage`، `openStoreDetail`، `openProductDetail`، `CartTokens` عبر `search_tokens.dart`.
- **Analytics:** `searchOpen`، `searchQuery`، `searchSuggestion`، `searchFilter`، `searchClearRecent`، `storeView`، `favoriteToggle`.
- **Tests:** `test/search_contract_test.dart`.

---

## Store Details = Reference Implementation v6 (مكتملة — Premium Polish)

شاشة **تفاصيل المتجر (Store Details)** اعتمدت **Reference Implementation v6** بعد Premium Polish على الهيكل الحالي (بدون إعادة تصميم الـ Layout):

- **ملفات:** `store_detail_screen.dart` + `widgets/matlob_store_detail_ui.dart`.
- **Hero:** تدرّج أنعم، دمج سفلي مع الجسم، ظلال/عمق، Parallax خفيف عبر `ValueNotifier` (بدون إعادة بناء القائمة).
- **Meta:** Verified badge، تقييم أوضح، ساعات العمل، شريط معلومات مصقول.
- **Search / Categories:** شريط زجاجي خفيف + Focus state؛ شرائح تصنيفات مفعّلة بانتقال AnimatedContainer.
- **Cards / CTA:** ظلال وصور وشارات `badgeLabel`، أول بطاقة «الأكثر طلباً» Featured؛ زر إضافة بـ Gradient + انتقال لـ Quantity Stepper من السلة.
- **Cart bar:** شريط بحري عائم مع BackdropFilter خفيف، Floating Shadow، شارة العدد وزر «عرض السلة».
- **Final Premium Polish / Production Candidate:** دمج Hero بدون خط فاصل (Gradient + Blur تدريجي)، Logo أصغر ~10%، Stepper دائري مع Press/Ripple، بطاقات موحّدة الارتفاع بلا تمييز Featured، قياسات `_StoreUi` للـ Radius/Shadows.

---

## Order Tracking = Reference Implementation v7 (مكتملة)

شاشة **تتبع الطلب (Order Tracking)** تعتمد **Reference Implementation v7** كمرجع نهائي لتجربة التتبع:

- **Architecture:** `lib/screens/home/tracking/**` — تكوين رفيع → `TrackingController` → `TrackingRepository` → `OrderService` / `UserRepository` / `StoreRepository` / `OrderTrackingRoutesLoader` / Cancel / Reorder. Barrel: `lib/screens/home/order_tracking_screen.dart` (`openOrderTracking`).
- **UI SSOT:** Hero خريطة (رجوع + شارة تتبع مباشر نابضة + علامات مندوب/وجهة)، Bottom Sheet (مقبض + بطاقة ETA + Timeline رأسي 4 مراحل + بطاقة مندوب مع اتصال/محادثة SMS).
- **Realtime:** تحديثات الطلب عبر `OrderService` listenable، موقع المندوب عبر `watchUser`، مسارات Directions مع debounce، ETA/مسافة/حالة بدون إعادة فتح الشاشة.
- **States:** loading / waitingDriver / preparing / onTheWay / delivered / cancelled / offline / error + Waiting State عند غياب المندوب.
- **Reuse:** `OrderTrackingMap` / Placeholder، `trackingCallDriver` / `trackingMessageDriver`، `showDriverRatingSheet`، `OrderTrackingUiData`، `TrackingTokens` عبر `CartTokens` / `AppColors`.
- **Tests:** `test/tracking_contract_test.dart`.

---

## Profile = Reference Implementation v8 (مكتملة)

شاشة **حسابي (Profile Dashboard)** تعتمد **Reference Implementation v8** كلوحة تحكم شخصية:

- **Architecture:** `lib/screens/home/profile/**` — تكوين رفيع → `ProfileController` → `ProfileRepository` → Auth / Orders / Favorites / Theme / AppConfig. Barrel: `lib/screens/home/tabs/profile_tab.dart`.
- **UI SSOT:** Header Navy + Hero Card + إحصائيات (طلبات/مفضلة) + وصول سريع (عناوين/دفع/قسائم/دعوة) + آخر نشاط + مجموعات إعدادات + خروج Accent.
- **Realtime:** أعداد الطلبات/المفضلة/آخر طلب تتحدث مع Listenables بدون إعادة فتح.
- **Actions:** Edit Profile، عناوين (`showCartAddressSheet`)، إشعارات، Dark Mode عبر `ThemeService`، استعادة كلمة المرور، دعم، خصوصية/شروط، تقييم التطبيق، Logout مع تأكيد.
- **Tokens / Tests:** `profile_tokens.dart`، `test/profile_contract_test.dart`.

---

## نموذج التنفيذ: Sprintان لكل شاشة

بدل سلسلة المراحل الطويلة (Phase 0 → 1 → Review → Polish → Approve)، كل شاشة تُنفَّذ كالتالي:

```
Sprint 1  →  تقرير واحد
     ↓
Sprint 2  →  تقرير نهائي + اعتماد
```

### Sprint 1 — البناء الأساسي (تطوير فقط)

يُنجز في سبرنت واحد:

- استخراج Widgets
- Pixel Perfect / Tokens
- Controller + Repository
- Firestore + Cloud Functions + Realtime
- Animations
- Accessibility أساسي

**تقرير واحد بعد اكتمال Sprint 1 فقط** — لا تقارير بعد كل تعديل صغير.

### Sprint 2 — المراجعة والصقل (مرة واحدة)

يجمع في سبرنت واحد:

- Engineering Review (Critical/High تُصلح فورًا)
- Performance / Profile
- Golden Tests
- Accessibility / WCAG اكتمال
- Production Polish

ثم **تقرير نهائي** وقرار اعتماد.

### ترتيب الشاشات بعد Cart

| الشاشة | التنفيذ |
|---|---|
| Checkout | ✅ مكتملة — RI v2 |
| Product Details | ✅ مكتملة — RI v3 |
| Orders | ✅ مكتملة — RI v4 |
| Search | ✅ مكتملة — RI v5 |
| Store Details | ✅ مكتملة — RI v6 (Premium Polish) |
| Order Tracking | ✅ مكتملة — RI v7 |
| Profile | ✅ مكتملة — RI v8 |
| Release Candidate | RC-1..RC-3 + مراجعة شاملة |

---

## اعتماد Cart المشروط (Option A)

- **الحالة:** معتمد كمرجع (93% Production Readiness).
- **النقص ~2%:** بيئة قياس (جهاز حقيقي / DevTools / Cairo في Goldens) — ليست عيوب منطق.

### Release Readiness Tasks (قبل الإطلاق النهائي فقط)

| # | المهمة |
|---|---|
| RC-1 | Profile على جهاز Android حقيقي |
| RC-2 | DevTools Memory/Profile + إرفاق التقرير |
| RC-3 | Cairo محلي + إعادة توليد Golden Baselines |
