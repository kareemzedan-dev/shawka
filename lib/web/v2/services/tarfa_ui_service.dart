import 'package:flutter/foundation.dart';

/// In-memory favorites for web v2 UI.
class TarfaFavoritesService extends ChangeNotifier {
  TarfaFavoritesService._();
  static final TarfaFavoritesService instance = TarfaFavoritesService._();

  final Set<String> _ids = {};

  int get count => _ids.length;

  bool isFavorite(String storeId) => _ids.contains(storeId);

  void toggle(String storeId) {
    if (_ids.contains(storeId)) {
      _ids.remove(storeId);
    } else {
      _ids.add(storeId);
    }
    notifyListeners();
  }
}
