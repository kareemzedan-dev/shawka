import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/user_role.dart';

/// قرار دخول العميل للتطبيق بعد المصادقة.
enum CustomerAccessDecision {
  /// ضيف أو غير عميل — لا قيود موافقة عميل.
  allow,
  /// معتمد ونشط.
  allowApproved,
  /// أكمل البيانات وبانتظار الأدمن.
  pendingReview,
  /// توقّف قبل صورة الإثبات/العنوان.
  incompleteSignup,
  /// مرفوض من الأدمن.
  rejected,
  /// معطّل.
  disabled,
  /// لا يوجد ملف Firestore.
  missingProfile,
}

/// بوابة وصول موحّدة — المصدر الوحيد لقرار Home / Pending / Signup / Login.
abstract final class CustomerAccess {
  static CustomerAccessDecision decide(AppUser? user) {
    if (user == null) return CustomerAccessDecision.missingProfile;
    if (user.isGuest || user.role != UserRole.customer) {
      return CustomerAccessDecision.allow;
    }

    final status = user.customerApprovalStatus.trim();

    if (status == 'rejected') return CustomerAccessDecision.rejected;
    if (user.isCustomerSignupIncomplete) {
      return CustomerAccessDecision.incompleteSignup;
    }
    if (status == 'pending') return CustomerAccessDecision.pendingReview;
    if (status == 'approved') {
      return user.isActive
          ? CustomerAccessDecision.allowApproved
          : CustomerAccessDecision.disabled;
    }

    // حسابات قديمة بلا حقل حالة: مسموح فقط إن كانت نشطة وليست ناقصة.
    if (status.isEmpty) {
      if (!user.isActive) return CustomerAccessDecision.disabled;
      return CustomerAccessDecision.allowApproved;
    }

    return CustomerAccessDecision.disabled;
  }

  static bool canEnterHome(AppUser? user) {
    final d = decide(user);
    return d == CustomerAccessDecision.allow ||
        d == CustomerAccessDecision.allowApproved ||
        d == CustomerAccessDecision.pendingReview;
  }

  static String denialMessage(CustomerAccessDecision decision) {
    return switch (decision) {
      CustomerAccessDecision.incompleteSignup =>
        'حسابك غير مكتمل — أكمل صورة الإثبات والعنوان من إنشاء الحساب',
      CustomerAccessDecision.pendingReview =>
        'حسابك قيد مراجعة الإدارة — لا يمكن الدخول قبل الموافقة',
      CustomerAccessDecision.rejected =>
        'تم رفض طلب التسجيل. أنشئ حساباً جديداً بصورة إثبات أوضح.',
      CustomerAccessDecision.disabled =>
        'هذا الحساب غير مفعّل. تواصل مع الدعم.',
      CustomerAccessDecision.missingProfile =>
        'تعذّر تحميل ملفك — سجّل الدخول مرة أخرى',
      CustomerAccessDecision.allow ||
      CustomerAccessDecision.allowApproved =>
        '',
    };
  }
}
