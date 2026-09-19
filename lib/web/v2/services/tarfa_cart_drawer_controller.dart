import 'package:flutter/foundation.dart';

/// Controls cart drawer visibility from anywhere in v2 shell.
class TarfaCartDrawerController extends ChangeNotifier {
  TarfaCartDrawerController._();
  static final TarfaCartDrawerController instance =
      TarfaCartDrawerController._();

  bool _open = false;

  bool get isOpen => _open;

  void open() {
    if (_open) return;
    _open = true;
    notifyListeners();
  }

  void close() {
    if (!_open) return;
    _open = false;
    notifyListeners();
  }

  void toggle() => _open ? close() : open();
}
