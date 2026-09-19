import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract final class FirestoreErrorMessage {
  static String from(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'resource-exhausted':
          return 'تم تجاوز حد الطلبات — انتظر دقيقة ثم حاول مجدداً.';
        case 'permission-denied':
          return 'صلاحية مرفوضة — دورك الحالي لا يسمح بهذه العملية.';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً.';
        default:
          return error.message ?? 'خطأ Cloud Function: ${error.code}';
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'صلاحية مرفوضة — دورك الحالي لا يسمح بهذه العملية. '
              'تواصل مع Super Admin إذا كنت تحتاج صلاحية إضافية.';
        case 'unauthorized':
          return 'صلاحية Storage مرفوضة — انشر قواعد التخزين: '
              'firebase deploy --only storage';
        case 'quota-exceeded':
          return 'مساحة Firebase Storage ممتلئة. '
              'احذف صوراً قديمة من Firebase Console → Storage، '
              'أو فعّل خطة Blaze من firebase.google.com/pricing';
        case 'failed-precondition':
          return 'فهرس Firestore ناقص — شغّل: firebase deploy --only firestore:indexes';
        case 'unavailable':
          return 'تحقق من اتصال الإنترنت';
        default:
          final message = error.message ?? '';
          if (message.contains('quota') && message.contains('exceeded')) {
            return 'مساحة Firebase Storage ممتلئة. '
                'احذف ملفات قديمة من Console أو رقِّ الخطة.';
          }
          if (error.plugin == 'firebase_storage') {
            return message.isNotEmpty
                ? message
                : 'خطأ Storage: ${error.code}';
          }
          return message.isNotEmpty
              ? message
              : 'خطأ Firestore: ${error.code}';
      }
    }
    if (error is FirebaseAuthException) {
      return error.message ?? 'خطأ تسجيل الدخول';
    }
    final text = error.toString();
    if (text.contains('quota-exceeded') || text.contains('storage/quota')) {
      return 'مساحة Firebase Storage ممتلئة. '
          'احذف ملفات قديمة من Firebase Console → Storage.';
    }
    return text;
  }

  static bool isStorageQuotaError(Object error) {
    if (error is FirebaseException && error.code == 'quota-exceeded') {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('quota-exceeded') ||
        text.contains('storage/quota') ||
        (text.contains('quota') && text.contains('exceeded'));
  }
}
