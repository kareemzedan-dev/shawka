import 'package:cloud_functions/cloud_functions.dart';

class AdminSettlementService {
  AdminSettlementService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> reviewRequest({
    required String requestId,
    required String action,
    String? reviewReason,
    double? amount,
  }) async {
    await _functions.httpsCallable('reviewSettlementRequest').call({
      'requestId': requestId,
      'action': action,
      if (reviewReason != null && reviewReason.trim().isNotEmpty)
        'reviewReason': reviewReason.trim(),
      'amount': ?amount,
    });
  }
}
