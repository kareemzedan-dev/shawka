import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AdminGpsService {
  AdminGpsService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  /// يعيد ثقة GPS للمندوب ويتأكد من تحديث المستند فعلياً.
  Future<void> resetDriverGpsTrust({required String driverId}) async {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw StateError('معرّف المندوب غير صالح');
    }

    Object? callableError;
    try {
      await _functions.httpsCallable('adminResetDriverGpsTrust').call({
        'driverId': id,
      });
    } catch (e, st) {
      callableError = e;
      debugPrint('adminResetDriverGpsTrust callable failed: $e');
      debugPrintStack(stackTrace: st);
    }

    // تأكيد الحالة — لو الـ Callable فشل أو تأخر، نكتب مباشرة (صلاحية أدمن).
    final trusted = await _isTrusted(id);
    if (trusted) return;

    await _resetViaFirestore(id);

    final verified = await _isTrusted(id);
    if (!verified) {
      throw callableError ??
          StateError('تعذّر استعادة GPS — تحقق من الصلاحيات والاتصال');
    }
  }

  Future<bool> _isTrusted(String driverId) async {
    final snap = await _firestore.collection('users').doc(driverId).get();
    if (!snap.exists) return false;
    final status = '${snap.data()?['gpsTrustStatus'] ?? ''}'.trim();
    return status.isEmpty || status == 'trusted';
  }

  Future<void> _resetViaFirestore(String driverId) async {
    final ref = _firestore.collection('users').doc(driverId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('المندوب غير موجود');
    }
    final data = snap.data() ?? {};
    final role = '${data['role'] ?? data['rule'] ?? ''}';
    if (role != 'delivery') {
      throw StateError('المندوب غير موجود');
    }

    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    final loc = data['location'];
    final locLat = loc is GeoPoint ? loc.latitude : null;
    final locLng = loc is GeoPoint ? loc.longitude : null;
    final baselineLat = lat ?? locLat;
    final baselineLng = lng ?? locLng;

    final update = <String, dynamic>{
      'gpsTrustStatus': 'trusted',
      'gpsViolationCount24h': 0,
      'assignmentEligibleUntil': FieldValue.delete(),
      'locationRejectedAt': FieldValue.delete(),
      'isDriverOnline': false,
      'gpsAdminResetAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (baselineLat != null && baselineLng != null) {
      update['lastValidLatitude'] = baselineLat;
      update['lastValidLongitude'] = baselineLng;
      update['lastValidLocationAt'] = FieldValue.serverTimestamp();
    } else {
      update['lastValidLatitude'] = FieldValue.delete();
      update['lastValidLongitude'] = FieldValue.delete();
      update['lastValidLocationAt'] = FieldValue.delete();
    }

    await ref.update(update);
  }
}
