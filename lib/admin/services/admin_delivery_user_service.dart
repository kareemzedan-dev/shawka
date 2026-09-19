import 'package:cloud_functions/cloud_functions.dart';

class AdminDeliveryUserService {
  AdminDeliveryUserService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<String> createDeliveryUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String governorate,
  }) async {
    final result = await _functions.httpsCallable('adminCreateDeliveryUser').call({
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'phone': phone.trim(),
      'governorate': governorate.trim(),
    });
    final data = result.data;
    if (data is Map && data['uid'] is String) {
      return data['uid'] as String;
    }
    throw Exception('لم يُرجع السيرفر معرف المندوب');
  }
}
