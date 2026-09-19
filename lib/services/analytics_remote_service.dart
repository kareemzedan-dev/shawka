import 'package:cloud_functions/cloud_functions.dart';
import 'package:matlobgo/models/analytics_event.dart';

/// يرسل أحداث Analytics عبر Cloud Function — Rate Limited على السيرفر.
class AnalyticsRemoteService {
  AnalyticsRemoteService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> track(AnalyticsEvent event) async {
    try {
      await _functions.httpsCallable('trackAnalyticsEvent').call({
        'type': event.type.firestoreValue,
        'screen': event.screen,
        'label': event.label,
        'userName': event.userName,
        'storeId': event.storeId,
        'storeName': event.storeName,
        'productId': event.productId,
        'productName': event.productName,
        'metadata': event.metadata,
      });
    } catch (_) {
      // Analytics is best-effort; do not crash the app if Functions are unavailable.
    }
  }
}
