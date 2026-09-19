import 'package:cloud_functions/cloud_functions.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/services/auth_claims_service.dart';

/// تغيير staffRole / تعيين صاحب متجر عبر Cloud Functions.
class AdminRolesService {
  AdminRolesService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> setStaffRole({
    required String targetUid,
    required AdminStaffRole staffRole,
    List<String> managedStoreIds = const [],
  }) async {
    await _functions.httpsCallable('adminSetStaffRole').call({
      'targetUid': targetUid,
      'staffRole': staffRole.firestoreValue,
      if (managedStoreIds.isNotEmpty) 'managedStoreIds': managedStoreIds,
    });

    await AuthClaimsService.instance.refreshClaims();
  }

  /// ترقية حساب (رقم موبايل أو UID) إلى صاحب متجر مربوط بمتاجر محددة.
  Future<Map<String, dynamic>> assignStoreOwner({
    String? targetUid,
    String? targetPhone,
    String? targetEmail,
    required List<String> managedStoreIds,
  }) async {
    final result = await _functions.httpsCallable('adminAssignStoreOwner').call({
      if (targetUid != null && targetUid.isNotEmpty) 'targetUid': targetUid,
      if (targetPhone != null && targetPhone.isNotEmpty)
        'targetPhone': targetPhone,
      if (targetEmail != null && targetEmail.isNotEmpty)
        'targetEmail': targetEmail,
      'managedStoreIds': managedStoreIds,
    });
    await AuthClaimsService.instance.refreshClaims();
    return Map<String, dynamic>.from(result.data as Map? ?? {});
  }

  /// إزالة صاحب متجر وإرجاعه كعميل عادي.
  Future<Map<String, dynamic>> removeStoreOwner({
    required String targetUid,
  }) async {
    final result = await _functions.httpsCallable('adminRemoveStoreOwner').call({
      'targetUid': targetUid,
    });
    await AuthClaimsService.instance.refreshClaims();
    return Map<String, dynamic>.from(result.data as Map? ?? {});
  }

  /// إنشاء حساب موظف/مساعد للوحة التحكم (بريد + كلمة مرور).
  Future<Map<String, dynamic>> createStaffUser({
    required String name,
    required String email,
    required String password,
    String phone = '',
    AdminStaffRole staffRole = AdminStaffRole.storeAssistant,
  }) async {
    final result = await _functions.httpsCallable('adminCreateStaffUser').call({
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      'staffRole': staffRole.firestoreValue,
    });
    await AuthClaimsService.instance.refreshClaims();
    return Map<String, dynamic>.from(result.data as Map? ?? {});
  }
}
