import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Translates checkout Cloud Function failures into clear Arabic copy.
String checkoutErrorMessage(Object error) {
  final code = _serverCode(error);
  switch (code) {
    case 'CUSTOMER_ROLE_REQUIRED':
      return 'هذا الحساب غير مخصص للطلب — استخدم حساب عميل';
    case 'USER_DISABLED':
      return 'تم إيقاف هذا الحساب — تواصل مع الدعم';
    case 'GUEST_CHECKOUT_DISABLED':
      return 'الطلب كضيف غير متاح — أنشئ حساباً أو سجّل دخولك لإتمام الطلب';
    case 'ACCOUNT_PENDING_APPROVAL':
      return 'حسابك قيد المراجعة — تقدر تتصفح المنتجات، والطلب متاح بعد موافقة الأدمن';
    case 'USER_PROFILE_MISSING':
      return 'تعذّر العثور على بيانات حسابك — سجّل الخروج ثم الدخول';
    case 'MAINTENANCE_MODE':
      return 'التطبيق في وضع الصيانة — حاول لاحقاً';
    case 'INVALID_COUPON':
      return 'كود الخصم غير صالح أو منتهي';
    case 'PROMOTION_USAGE_EXHAUSTED':
      return 'انتهى الحد الأقصى لاستخدام هذا العرض';
    case 'PROMOTION_USER_LIMIT_EXHAUSTED':
      return 'لقد استخدمت هذا العرض بالحد الأقصى المسموح';
    case 'PROMOTION_MINIMUM_NOT_MET':
      return 'قيمة الطلب أقل من الحد الأدنى لهذا العرض';
    case 'MINIMUM_ORDER_NOT_MET':
      return 'قيمة الطلب أقل من الحد الأدنى للمتجر';
    case 'INSUFFICIENT_STOCK':
      return 'بعض المنتجات نفدت من المخزون — حدّث السلة';
    case 'CUSTOMER_QUANTITY_LIMIT':
      return 'تجاوزت الحد الأقصى المسموح لبعض المنتجات — حدّث السلة';
    case 'PRODUCT_UNAVAILABLE':
    case 'PRODUCT_NOT_FOUND':
    case 'INVALID_PRODUCT':
    case 'INVALID_ADDON':
      return 'بعض المنتجات لم تعد متاحة — حدّث السلة';
    case 'STORE_UNAVAILABLE':
    case 'STORE_NOT_FOUND':
    case 'STORE_OUT_OF_GOVERNORATE':
    case 'STORE_OUT_OF_DELIVERY_ZONE':
    case 'STORE_LOCATION_MISSING':
      return 'المتجر غير متاح حالياً في منطقتك';
    case 'PAYMENT_METHOD_UNAVAILABLE':
    case 'INVALID_PAYMENT_METHOD':
      return 'وسيلة الدفع المحددة غير متاحة لهذا الطلب';
    case 'INVALID_DELIVERY_COORDINATES':
    case 'DELIVERY_ADDRESS_REQUIRED':
      return 'حدّد عنوان توصيل صالح من الخريطة';
    case 'CHECKOUT_QUOTE_REQUIRED':
    case 'CHECKOUT_PRICING_FAILED':
      return 'تعذّر حساب تكلفة الطلب — أعد المحاولة';
    case 'CHECKOUT_ALREADY_IN_PROGRESS':
      return 'جارٍ إنشاء طلبك بالفعل — انتظر لحظة';
    case 'OUT_OF_DELIVERY_RANGE':
    case 'DELIVERY_OUT_OF_RANGE':
    case 'ADDRESS_OUT_OF_ZONE':
      return 'العنوان خارج نطاق التوصيل — اختر موقعاً أقرب';
  }

  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      'unauthenticated' => 'سجّل دخولك أولاً لإتمام الطلب',
      'permission-denied' => 'ليست لديك صلاحية لإتمام هذا الطلب',
      'resource-exhausted' => 'تم تجاوز حد الطلبات — حاول بعد قليل',
      'unavailable' => 'الخدمة غير متاحة مؤقتاً — حاول لاحقاً',
      'not-found' => 'خدمة الدفع غير جاهزة بعد — أعد المحاولة بعد لحظات',
      'deadline-exceeded' => 'انتهت مهلة الاتصال — أعد المحاولة',
      'invalid-argument' => 'بيانات الطلب غير صالحة — راجع السلة والعنوان',
      'internal' => 'حدث خطأ في الخادم أثناء حساب الطلب — أعد المحاولة',
      _ => 'تعذّر تحديث بيانات الطلب — أعد المحاولة',
    };
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'unauthenticated' => 'سجّل دخولك أولاً لإتمام الطلب',
      'permission-denied' => 'ليست لديك صلاحية لإتمام هذا الطلب',
      'unavailable' => 'الخدمة غير متاحة مؤقتاً — حاول لاحقاً',
      _ => 'تعذّر تحديث بيانات الطلب — أعد المحاولة',
    };
  }

  return 'تعذّر تحديث بيانات الطلب — أعد المحاولة';
}

String _serverCode(Object error) {
  final candidates = <String>[];
  if (error is FirebaseFunctionsException) {
    candidates.add(error.message ?? '');
    final details = error.details;
    if (details is String) candidates.add(details);
    if (details is Map) {
      candidates.add('${details['message'] ?? ''}');
      candidates.add('${details['status'] ?? ''}');
    }
  } else if (error is FirebaseException) {
    candidates.add(error.message ?? '');
  } else if (error is StateError) {
    candidates.add(error.message);
  } else {
    candidates.add(error.toString());
  }

  for (final raw in candidates) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) continue;
    final match = RegExp(r'[A-Z][A-Z0-9_]+').firstMatch(normalized);
    if (match != null) return match.group(0)!;
  }
  return '';
}
