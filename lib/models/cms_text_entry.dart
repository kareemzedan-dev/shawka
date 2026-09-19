import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';

class CmsTextEntry {
  const CmsTextEntry({
    required this.id,
    required this.key,
    required this.label,
    required this.value,
    required this.updatedAt,
  });

  final String id;
  final String key;
  final String label;
  final String value;
  final DateTime updatedAt;

  factory CmsTextEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CmsTextEntry(
      id: doc.id,
      key: data['key'] as String? ?? doc.id,
      label: data['label'] as String? ?? doc.id,
      value: data['value'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'key': key,
      'label': label,
      'value': value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

abstract final class CmsTextDefaults {
  static final entries = [
    (
      'welcome_guest',
      'رسالة ترحيب — ضيف',
      'مرحباً بك في ${BrandingValues.appName}',
    ),
    ('welcome_user', 'رسالة ترحيب — مسجل', 'مرحباً {name}'),
    ('empty_orders', 'لا طلبات', 'لم تقم بأي طلب بعد'),
    ('empty_favorites', 'لا مفضلات', 'ابدأ بإضافة متاجرك المفضلة'),
    ('promo_hint', 'تلميح العروض', 'استخدم كود الخصم في السلة'),
    ('empty_cart_title', 'عنوان سلة فارغة', 'سلتك فارغة حالياً'),
    ('empty_cart_subtitle', 'وصف سلة فارغة', 'ابدأ بإضافة منتجاتك المفضلة'),
    (
      'home_search_hint',
      'تلميح البحث (الرئيسية — افصل بـ |)',
      'ابحث عن مورد أو منتج',
    ),
    ('home_most_ordered_title', 'عنوان الأكثر طلباً', 'الأكثر طلباً'),
    ('home_best_selling_title', 'عنوان الأكثر مبيعاً', 'الأكثر مبيعًا 🔥'),
    ('home_offers_label', 'تصنيف العروض', 'عروض'),
    ('home_track_order', 'زر تفاصيل الطلب', 'تفاصيل'),
    ('home_free_delivery', 'نص توصيل مجاني', 'توصيل مجاني'),
    ('home_view_all', 'عرض الكل', 'عرض الكل'),
    ('greeting_morning', 'تحية الصباح', 'صباح الخير'),
    ('greeting_evening', 'تحية المساء', 'مساء الخير'),
    (
      'greeting_guest_headline',
      'عنوان الترحيب بالضيف',
      'ماذا ترغب أن تطلب اليوم؟',
    ),
    ('greeting_seasonal', 'التحية الموسمية', ''),
    (
      'search_suggestions',
      'البحث — اقتراحات سريعة (افصل بـ |)',
      '',
    ),
    ('search_trending', 'البحث — الأكثر بحثاً (افصل بـ |)', ''),
    ('search_blacklist', 'البحث — كلمات ممنوعة (افصل بـ |)', ''),
    ('search_placeholder', 'البحث — تلميح حقل البحث', ''),
    ('search_page_title', 'البحث — عنوان الصفحة', ''),
    ('search_popular_title', 'البحث — عنوان الأكثر بحثاً', ''),
    ('search_recent_title', 'البحث — عنوان عمليات البحث الأخيرة', ''),
    ('search_recent_clear', 'البحث — زر مسح الكل', ''),
    ('search_filter_all', 'البحث — شريحة الكل', ''),
    (
      'search_suggested_stores_title',
      'البحث — عنوان الموردين المقترحين',
      '',
    ),
    (
      'search_suggested_stores_subtitle',
      'البحث — وصف الموردين المقترحين',
      '',
    ),
    ('checkout_title', 'Checkout — العنوان', 'إتمام الطلب'),
    (
      'checkout_subtitle',
      'Checkout — وصف العنوان',
      'باقي خطوة واحدة ويبدأ تجهيز طلبك',
    ),
    ('checkout_delivery_to', 'Checkout — التوصيل إلى', 'التوصيل إلى'),
    ('checkout_change_address', 'Checkout — تغيير العنوان', 'تغيير'),
    ('checkout_add_address', 'Checkout — إضافة عنوان', 'إضافة عنوان التوصيل'),
    ('checkout_payment_title', 'Checkout — الدفع', 'طريقة الدفع'),
    ('checkout_order_review_title', 'Checkout — مراجعة الطلب', 'مراجعة الطلب'),
    ('checkout_coupon_title', 'Checkout — الكوبون', 'هل لديك كود خصم؟'),
    ('checkout_coupon_hint', 'Checkout — تلميح الكوبون', 'أدخل كود الخصم'),
    ('checkout_apply_coupon', 'Checkout — تطبيق الكوبون', 'تطبيق'),
    (
      'checkout_coupon_cta_subtitle',
      'Checkout — وصف الكوبون',
      'أضف الكود واستمتع بالخصم',
    ),
    (
      'checkout_coupon_savings',
      'Checkout — نص التوفير',
      'تم توفير {amount} ج.م',
    ),
    ('checkout_summary_title', 'Checkout — ملخص السعر', 'ملخص الدفع'),
    ('checkout_subtotal', 'Checkout — المجموع الفرعي', 'المجموع الفرعي'),
    ('checkout_delivery_fee', 'Checkout — التوصيل', 'رسوم التوصيل'),
    ('checkout_discount', 'Checkout — الخصم', 'الخصم'),
    ('checkout_service_fee', 'Checkout — رسوم الخدمة', 'رسوم الخدمة'),
    ('checkout_payment_fee', 'Checkout — رسوم الدفع', 'رسوم الدفع'),
    ('checkout_taxes', 'Checkout — الضرائب', 'الضرائب'),
    ('checkout_total', 'Checkout — الإجمالي', 'الإجمالي'),
    ('checkout_confirm_order', 'Checkout — تأكيد الطلب', 'تأكيد الطلب'),
    (
      'checkout_summary_note',
      'Checkout — ملاحظة الملخص',
      'سيتم احتساب الإجمالي النهائي في الشريط أدناه',
    ),
    ('cart_title', 'السلة — العنوان', 'سلة التسوق'),
    ('cart_subtitle', 'السلة — الوصف', '{count} أصناف في سلتك'),
    ('cart_selected_items_title', 'السلة — الأصناف', 'الأصناف المختارة'),
    ('cart_clear_all', 'السلة — مسح الكل', 'مسح الكل'),
    ('cart_order_note_hint', 'السلة — ملاحظة الطلب', 'إضافة ملاحظة للطلب...'),
    ('cart_coupon_title', 'السلة — الكوبون', 'كوبون الخصم'),
    ('cart_coupon_apply', 'السلة — تطبيق الكوبون', 'تطبيق'),
    ('cart_suggestions_title', 'السلة — المقترحات', 'مقترحات لك'),
    ('cart_subtotal', 'السلة — المجموع الفرعي', 'المجموع الفرعي'),
    ('cart_discount_total', 'السلة — إجمالي الخصم', 'إجمالي الخصم'),
    ('cart_total', 'السلة — المجموع', 'المجموع'),
    ('cart_continue', 'السلة — متابعة الطلب', 'متابعة الطلب'),
    (
      'cart_free_delivery_near_title',
      'السلة — توصيل مجاني يقترب',
      'توصيل مجاني يقترب!',
    ),
    (
      'cart_free_delivery_near_body',
      'السلة — أضف للمبلغ',
      'أضف {amount} ج.م للحصول على العرض',
    ),
    (
      'cart_free_delivery_unlocked_title',
      'السلة — توصيل مجاني مفعّل',
      'مبروك! التوصيل مجاني',
    ),
    (
      'cart_free_delivery_unlocked_body',
      'السلة — وصف التوصيل المجاني',
      'وصلت للحد الأدنى — استمتع بالتوصيل المجاني',
    ),
    (
      'cart_stock_limit_reached',
      'السلة — حد المخزون',
      'وصلت للحد الأقصى المتاح من المخزون',
    ),
    (
      'cart_item_unavailable',
      'السلة — منتج غير متاح',
      'هذا المنتج لم يعد متاحاً — أزله من السلة',
    ),
    (
      'cart_price_updated',
      'السلة — تحديث السعر',
      'تم تحديث أسعار بعض المنتجات في سلتك',
    ),
    ('nav_home', 'التنقل — الرئيسية', 'الرئيسية'),
    ('nav_search', 'التنقل — بحث', 'بحث'),
    ('nav_cart', 'التنقل — السلة', 'السلة'),
    ('nav_orders', 'التنقل — طلباتي', 'طلباتي'),
    ('nav_profile', 'التنقل — حسابي', 'حسابي'),
  ];
}
