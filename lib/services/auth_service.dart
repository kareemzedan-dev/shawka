import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/customer_activity_type.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/services/auth_claims_service.dart';

class PhoneOtpSession {
  const PhoneOtpSession({
    required this.phoneE164,
    required this.sessionId,
    required this.delivery,
    this.inAppCode,
    this.expiresInSec = 300,
  });

  final String phoneE164;
  final String sessionId;
  final String delivery;
  final String? inAppCode;
  final int expiresInSec;

  bool get isInApp => delivery == 'in_app' && (inAppCode?.isNotEmpty ?? false);
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// إعدادات Auth: لا نفرض مسار reCAPTCHA على أندرويد.
  Future<void> configurePhoneAuthForInApp() async {
    try {
      await _auth.setSettings(forceRecaptchaFlow: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] setSettings failed: $e');
      }
    }
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// يتابع ملف المستخدم الحالي لحظياً (مثل تحديث موافقة الأدمن).
  Stream<AppUser?> watchCurrentAppUser() {
    return authStateChanges.asyncExpand((user) {
      if (user == null) return Stream<AppUser?>.value(null);
      return _firestore
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return AppUser.fromFirestore(doc);
      });
    });
  }

  /// تسجيل دخول العميل بالرقم + كلمة المرور (بدون OTP).
  Future<UserCredential> signInWithPhonePassword({
    required String phoneRaw,
    required String password,
  }) async {
    final email = EgyptianPhone.toAuthEmail(phoneRaw);
    if (email == null) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'رقم الموبايل غير صحيح',
      );
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await AuthClaimsService.instance.refreshClaims();
      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// بعد OTP: حفظ الاسم وكلمة المرور على حساب الموبايل.
  Future<void> setCustomerCredentials({
    required String name,
    required String password,
  }) async {
    if (currentUser == null) {
      throw StateError('No authenticated user');
    }
    try {
      await _functions.httpsCallable('setCustomerCredentials').call({
        'name': name.trim(),
        'password': password,
      });
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await AuthClaimsService.instance.refreshClaims();
    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await _saveUserProfile(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        isGuest: false,
      );
    }

    await AuthClaimsService.instance.refreshClaims();
    return credential;
  }

  /// إرسال OTP داخل التطبيق عبر Cloud Functions — بدون فتح Google/reCAPTCHA.
  /// [purpose]: `signup` يمنع إعادة التسجيل لرقم لديه كلمة مرور.
  Future<PhoneOtpSession> sendPhoneOtp({
    required String phoneRaw,
    String purpose = 'signup',
  }) async {
    final e164 = EgyptianPhone.toE164(phoneRaw);
    if (e164 == null) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'رقم الموبايل غير صحيح',
      );
    }

    try {
      final result = await _functions.httpsCallable('sendCustomerPhoneOtp').call({
        'phone': e164,
        'purpose': purpose,
      });
      final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
      final sessionId = (data['sessionId'] as String?)?.trim() ?? '';
      if (sessionId.isEmpty) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'تعذّر إنشاء جلسة التحقق',
        );
      }
      return PhoneOtpSession(
        phoneE164: e164,
        sessionId: sessionId,
        delivery: (data['delivery'] as String?)?.trim() ?? 'in_app',
        inAppCode: (data['code'] as String?)?.trim(),
        expiresInSec: (data['expiresInSec'] as num?)?.toInt() ?? 300,
      );
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    }
  }

  /// التحقق من OTP وتسجيل الدخول بـ custom token.
  Future<UserCredential> verifyPhoneOtp({
    required String phoneE164,
    required String sessionId,
    required String smsCode,
  }) async {
    try {
      final result =
          await _functions.httpsCallable('verifyCustomerPhoneOtp').call({
        'phone': phoneE164,
        'sessionId': sessionId,
        'code': smsCode.trim(),
      });
      final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
      final token = (data['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'تعذّر إكمال تسجيل الدخول',
        );
      }
      final credential = await _auth.signInWithCustomToken(token);
      await AuthClaimsService.instance.refreshClaims();
      return credential;
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    }
  }

  /// مسار Firebase Phone Auth القديم (قد يفتح reCAPTCHA عند فشل Play Integrity).
  @Deprecated('Use sendPhoneOtp / verifyPhoneOtp to avoid Google reCAPTCHA')
  Future<void> verifyPhoneNumber({
    required String phoneRaw,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(String verificationId)? onAutoRetrievalTimeout,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final e164 = EgyptianPhone.toE164(phoneRaw);
    if (e164 == null) {
      onFailed(
        FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'رقم الموبايل غير صحيح',
        ),
      );
      return;
    }

    await _auth.setSettings(forceRecaptchaFlow: false);
    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (verificationId) {
        onAutoRetrievalTimeout?.call(verificationId);
      },
    );
  }

  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return signInWithPhoneCredential(credential);
  }

  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final current = _auth.currentUser;
    UserCredential result;
    if (current != null && current.isAnonymous) {
      try {
        result = await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'provider-already-linked' ||
            e.code == 'email-already-in-use') {
          result = await _auth.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }
    } else {
      result = await _auth.signInWithCredential(credential);
    }

    await AuthClaimsService.instance.refreshClaims();
    return result;
  }

  /// يحفظ/يحدّث ملف عميل بعد التحقق من الموبايل + اختيار النشاط + صورة الإثبات.
  Future<AppUser> completePhoneCustomerProfile({
    required String phoneE164,
    required CustomerActivityType activityType,
    required String proofImageUrl,
    String proofImageThumbUrl = '',
    String? displayName,
    required String address,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }

    try {
      await _functions.httpsCallable('completeCustomerProfile').call({
        'phone': phoneE164,
        'activityTypeId': activityType.id,
        'activityTypeName': activityType.name,
        'proofImageUrl': proofImageUrl.trim(),
        'proofImageThumbUrl': proofImageThumbUrl.trim(),
        'displayName': displayName?.trim() ?? '',
        'address': address.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message,
      );
    }

    try {
      final name = displayName?.trim() ?? activityType.name;
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] updateDisplayName failed: $e');
      }
    }

    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .get();
    return AppUser.fromFirestore(doc);
  }

  Future<UserCredential> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;

    if (user != null) {
      await _saveUserProfile(
        uid: user.uid,
        name: 'ضيف',
        email: '',
        isGuest: true,
      );
    }

    await AuthClaimsService.instance.refreshClaims();
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// حذف حساب العميل الحالي عبر Cloud Function (Play / App Store requirement).
  Future<void> deleteMyAccount() async {
    try {
      await _functions.httpsCallable('deleteMyAccount').call();
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : 'تعذّر حذف الحساب — حاول لاحقاً');
    }
    try {
      await _auth.signOut();
    } catch (_) {
      // Auth user may already be deleted server-side.
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    String? phone,
    String? governorate,
    String? activityTypeId,
    String? activityTypeName,
  }) async {
    final trimmedName = name.trim();
    await _firestore.collection(FirestorePaths.users).doc(uid).set(
      {
        'name': trimmedName,
        if (phone != null) 'phone': phone.trim(),
        if (governorate != null) 'governorate': governorate.trim(),
        if (activityTypeId != null) 'activityTypeId': activityTypeId,
        if (activityTypeName != null) 'activityTypeName': activityTypeName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final user = currentUser;
    if (user != null && user.uid == uid && user.displayName != trimmedName) {
      await user.updateDisplayName(trimmedName);
    }
  }

  Future<void> _saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required bool isGuest,
  }) {
    final appUser = AppUser(
      uid: uid,
      name: name,
      email: email,
      isGuest: isGuest,
      createdAt: DateTime.now(),
      role: UserRole.customer,
    );

    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(appUser.toFirestore(), SetOptions(merge: true));
  }

  String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'هذا الحساب معطّل';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا الرقم — أنشئ حساباً جديداً';
      case 'wrong-password':
      case 'invalid-credential':
        return 'رقم الموبايل أو كلمة المرور غير صحيحة';
      case 'already-exists':
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'هذا الرقم مسجّل بالفعل — سجّل الدخول';
      case 'email-already-in-use':
        return 'هذا الرقم مسجّل بالفعل — سجّل الدخول';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل';
      case 'too-many-requests':
      case 'resource-exhausted':
        return 'محاولات كتير، جرّب تاني بعد شوية';
      case 'network-request-failed':
      case 'unavailable':
        return 'تحقق من اتصال الإنترنت';
      case 'invalid-phone-number':
      case 'invalid-argument':
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'رقم الموبايل أو الرمز غير صحيح';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
      case 'session-expired':
      case 'deadline-exceeded':
      case 'failed-precondition':
      case 'not-found':
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'انتهت صلاحية الرمز — اطلب رمزاً جديداً';
      case 'code-expired':
        return 'انتهت صلاحية الرمز — اطلب رمزاً جديداً';
      case 'quota-exceeded':
        return 'تم تجاوز حد الإرسال، حاول لاحقاً';
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return 'إعدادات التحقق من الموبايل غير مكتملة على الجهاز';
      case 'captcha-check-failed':
        return 'فشل التحقق الأمني، حاول مرة أخرى';
      case 'permission-denied':
        return 'غير مسموح بهذه العملية';
      case 'internal':
      case 'internal-error':
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'حدث خطأ، حاول مرة أخرى';
      default:
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'حدث خطأ، حاول مرة أخرى';
    }
  }
}
