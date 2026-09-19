import 'package:firebase_auth/firebase_auth.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/services/auth_claims_service.dart';
import 'package:matlobgo/services/auth_service.dart';

class AdminAuthService {
  AdminAuthService({AuthService? authService})
      : _auth = authService ?? AuthService();

  final AuthService _auth;

  User? get currentUser => _auth.currentUser;

  Future<AppUser?> signInAdmin({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmail(email: email, password: password);
    final appUser = await _auth.getCurrentAppUser();
    if (appUser == null) {
      await _auth.signOut();
      throw AdminAuthException(
        'حسابك موجود في Firebase لكن لا يوجد ملف في Firestore.\n'
        'افتح Firebase Console → Firestore → users → انسخ الـ UID من Authentication '
        '→ أنشئ مستنداً بالـ UID وأضف الحقل role = admin',
      );
    }
    if (!appUser.isAdmin) {
      await _auth.signOut();
      throw AdminAuthException(
        'هذا الحساب مسجّل كعميل (role: ${appUser.role.firestoreValue}).\n'
        'في Firebase Console → Firestore → users → مستند الـ UID الخاص بك '
        '→ عدّل الحقل role إلى admin ثم سجّل الدخول مرة أخرى.',
      );
    }
    await AuthClaimsService.instance.refreshClaims();
    final refreshed = await _auth.getCurrentAppUser();
    AdminSession.instance.bind(refreshed ?? appUser);
    await AdminSession.instance.record(
      action: AuditAction.login,
      entityType: 'admin',
      entityId: appUser.uid,
      summary: 'تسجيل دخول إلى لوحة التحكم',
    );
    return refreshed ?? appUser;
  }

  Future<void> signOut() => _auth.signOut();

  String mapError(Object error) {
    if (error is AdminAuthException) return error.message;
    if (error is FirebaseAuthException) {
      return _auth.mapAuthError(error);
    }
    return 'حدث خطأ، حاول مرة أخرى';
  }
}

class AdminAuthException implements Exception {
  AdminAuthException(this.message);
  final String message;
}
