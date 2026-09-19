import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Completer<bool>? _loading;
bool _ready = false;

bool get isGoogleMapsJsReady {
  if (_ready) return true;
  return _mapsObjectAvailable();
}

bool _mapsObjectAvailable() {
  try {
    final google = web.window.getProperty('google'.toJS);
    if (google == null) return false;
    final maps = (google as JSObject).getProperty('maps'.toJS);
    return maps != null;
  } catch (_) {
    return false;
  }
}

/// يحمّل Maps JavaScript API (+ Places) مرة واحدة على الويب.
Future<bool> ensureGoogleMapsJsLoaded(String apiKey) async {
  if (apiKey.trim().isEmpty) return false;
  if (isGoogleMapsJsReady) {
    _ready = true;
    return true;
  }
  if (_loading != null) return _loading!.future;

  final completer = Completer<bool>();
  _loading = completer;

  try {
    final existing = web.document.querySelector(
      'script[data-matlob-maps="1"]',
    );
    if (existing != null) {
      final ok = await _waitUntilReady();
      _ready = ok;
      if (!completer.isCompleted) completer.complete(ok);
      return completer.future;
    }

    final script = web.HTMLScriptElement()
      ..async = true
      ..src =
          'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey)}&libraries=places&language=ar';
    script.setAttribute('data-matlob-maps', '1');

    script.onload = ((web.Event _) {
      unawaited(() async {
        final ok = await _waitUntilReady();
        _ready = ok;
        if (!completer.isCompleted) completer.complete(ok);
      }());
    }).toJS;

    script.onerror = ((web.Event _) {
      if (!completer.isCompleted) completer.complete(false);
    }).toJS;

    (web.document.head ?? web.document.body)?.append(script);
  } catch (_) {
    if (!completer.isCompleted) completer.complete(false);
  }

  return completer.future;
}

Future<bool> _waitUntilReady() async {
  for (var i = 0; i < 60; i++) {
    if (_mapsObjectAvailable()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return _mapsObjectAvailable();
}
