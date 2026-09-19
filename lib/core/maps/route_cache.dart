import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/maps/directions_route.dart';

/// ذاكرة مؤقتة لمسارات Directions — تقليل استدعاءات API.
class RouteCache {
  RouteCache._();
  static final RouteCache instance = RouteCache._();

  final _cache = <String, _CacheEntry>{};
  static const _maxEntries = 48;
  static const _ttl = Duration(minutes: 12);

  String _key(LatLng a, LatLng b, {String mode = 'driving'}) {
    return '${a.latitude.toStringAsFixed(5)},${a.longitude.toStringAsFixed(5)}->'
        '${b.latitude.toStringAsFixed(5)},${b.longitude.toStringAsFixed(5)}:$mode';
  }

  DirectionsRoute? get(LatLng origin, LatLng destination, {String mode = 'driving'}) {
    final entry = _cache[_key(origin, destination, mode: mode)];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > _ttl) {
      _cache.remove(_key(origin, destination, mode: mode));
      return null;
    }
    return entry.route;
  }

  void put(LatLng origin, LatLng destination, DirectionsRoute route, {String mode = 'driving'}) {
    if (!route.isValid) return;
    final k = _key(origin, destination, mode: mode);
    _cache[k] = _CacheEntry(route: route, at: DateTime.now());
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  void clear() => _cache.clear();
}

class _CacheEntry {
  _CacheEntry({required this.route, required this.at});
  final DirectionsRoute route;
  final DateTime at;
}
