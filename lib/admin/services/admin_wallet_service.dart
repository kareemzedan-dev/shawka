import 'package:cloud_functions/cloud_functions.dart';

class AdminWalletService {
  AdminWalletService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> depositSettlement({
    required String driverId,
    required double amount,
    String? notes,
  }) async {
    await _functions.httpsCallable('adminWalletSettlement').call({
      'driverId': driverId,
      'amount': amount,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }
}
