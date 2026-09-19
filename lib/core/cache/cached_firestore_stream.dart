import 'dart:async';

import 'package:matlobgo/core/cache/cache_policy.dart';
import 'package:matlobgo/core/cache/firestore_cache_store.dart';

/// Stream Firestore مع إصدار فوري من الكاش ثم التحديث المباشر.
Stream<T> cachedFirestoreStream<T>({
  required String cacheKey,
  required CachePolicyConfig policy,
  required Stream<T> source,
  required T Function(List<dynamic> json) decode,
  required List<dynamic> Function(T value) encode,
}) {
  final controller = StreamController<T>.broadcast();
  StreamSubscription<T>? sub;
  var disposed = false;

  Future<void> bootstrap() async {
    final cached = await FirestoreCacheStore.instance.read<T>(
      key: cacheKey,
      decode: decode,
      maxAge: policy.diskTtl,
    );
    if (!disposed && cached != null && !controller.isClosed) {
      controller.add(cached);
    }

    sub = source.listen(
      (data) async {
        if (disposed || controller.isClosed) return;
        controller.add(data);
        await FirestoreCacheStore.instance.write(
          key: cacheKey,
          value: data,
          encode: encode,
        );
      },
      onError: controller.addError,
    );
  }

  unawaited(bootstrap());

  controller.onCancel = () async {
    disposed = true;
    await sub?.cancel();
  };

  return controller.stream;
}
