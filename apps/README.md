# تطبيقات Shawka المنفصلة

هذا المجلد يوثّق التطبيقات المنفصلة التي ستشارك نفس Firebase.

| المجلد المقترح | الوصف |
|----------------|--------|
| `../` (الجذر) | تطبيق العميل + لوحة التحكم (entry points مختلفة) |
| `delivery/` | تطبيق الدليفري — يُنشأ كمشروع Flutter جديد |
| `customer_web/` | موقع العميل — Flutter Web أو React |

كل مشروع يستخدم:

- نفس `projectId`: `shawka-689fa`
- نفس `firebase_options` / `google-services.json`
- package مشترك تقني (عند الاستخراج)
