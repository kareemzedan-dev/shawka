import 'package:cloud_functions/cloud_functions.dart';

/// تقييم المندوب بعد التوصيل — عبر Cloud Function لتحديث آمن.
class DriverRatingService {
  DriverRatingService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> submitRating({
    required String orderId,
    required int rating,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('التقييم يجب أن يكون بين 1 و 5');
    }
    try {
      await _functions.httpsCallable('submitDriverRating').call({
        'orderId': orderId,
        'rating': rating,
      });
    } on FirebaseFunctionsException catch (error) {
      throw DriverRatingException(
        message: _messageForCode(error.code, error.message),
        code: error.code,
      );
    }
  }

  static String _messageForCode(String code, String? fallback) {
    return switch (code) {
      'unauthenticated' => 'يجب تسجيل الدخول لتقييم المندوب.',
      'permission-denied' => 'لا يمكنك تقييم هذا الطلب.',
      'not-found' => 'الطلب غير موجود.',
      'failed-precondition' => fallback?.isNotEmpty == true
          ? fallback!
          : 'الطلب لم يُسلّم بعد أو لا يوجد مندوب.',
      'already-exists' => 'تم تقييم هذا الطلب مسبقاً.',
      'invalid-argument' => fallback?.isNotEmpty == true
          ? fallback!
          : 'بيانات التقييم غير صالحة.',
      'resource-exhausted' => 'محاولات كثيرة — حاول بعد قليل.',
      _ => 'تعذّر إرسال التقييم — حاول مرة أخرى.',
    };
  }
}

class DriverRatingException implements Exception {
  const DriverRatingException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
