import 'package:cloud_functions/cloud_functions.dart';

class AdminCustomerReviewService {
  AdminCustomerReviewService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> review({
    required String customerId,
    required String decision,
    String note = '',
  }) async {
    await _functions.httpsCallable('adminReviewCustomer').call({
      'customerId': customerId,
      'decision': decision,
      'note': note,
    });
  }

  Future<void> approve(String customerId, {String note = ''}) =>
      review(customerId: customerId, decision: 'approved', note: note);

  Future<void> reject(String customerId, {String note = ''}) =>
      review(customerId: customerId, decision: 'rejected', note: note);

  /// حذف حساب عميل نهائياً (Auth + Firestore + صور الإثبات).
  Future<void> deleteCustomer(String customerId, {String note = ''}) async {
    await _functions.httpsCallable('adminDeleteCustomer').call({
      'customerId': customerId,
      if (note.trim().isNotEmpty) 'note': note.trim(),
    });
  }
}
