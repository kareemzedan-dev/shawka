import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// يزامن Custom Claims (JWT) مع Firestore — يُستدعى بعد تسجيل الدخول.
class AuthClaimsService {
  AuthClaimsService._();

  static final AuthClaimsService instance = AuthClaimsService._();

  static const _callTimeout = Duration(seconds: 12);
  static const _maxAttempts = 3;

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// لا يرمي استثناء — فشل المزامنة لا يجب أن يعطّل التسجيل أو الدخول.
  Future<void> refreshClaims() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        await _functions
            .httpsCallable('refreshAuthClaims')
            .call()
            .timeout(_callTimeout);
        await user.getIdToken(true);
        return;
      } on FirebaseFunctionsException catch (e) {
        final retryable = e.code == 'not-found' || e.code == 'unavailable';
        if (retryable && attempt < _maxAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 350 * (attempt + 1)),
          );
          continue;
        }
        if (kDebugMode) {
          debugPrint('refreshAuthClaims failed (${e.code}): ${e.message}');
        }
        return;
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint('refreshAuthClaims timed out (attempt ${attempt + 1})');
        }
        if (attempt < _maxAttempts - 1) continue;
        return;
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('refreshAuthClaims error: $e\n$st');
        }
        return;
      }
    }
  }
}
