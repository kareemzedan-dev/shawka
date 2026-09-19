import 'package:flutter/foundation.dart';

/// قياس أوقات التشغيل — يظهر في Debug Console أثناء التطوير.
abstract final class StartupTiming {
  static final Stopwatch _watch = Stopwatch();
  static bool _started = false;

  static void start() {
    if (_started) return;
    _started = true;
    _watch
      ..reset()
      ..start();
    mark('app_start');
  }

  static void mark(String label) {
    if (!kDebugMode) return;
    debugPrint('[StartupTiming] $label: ${_watch.elapsedMilliseconds}ms');
  }

  static int get elapsedMs => _watch.elapsedMilliseconds;
}
