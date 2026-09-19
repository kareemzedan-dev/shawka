import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matlobgo/core/data/egypt_places_catalog.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';

/// نتيجة بحث جغرافي جاهزة بالإحداثيات (بدون خطوة ثانية).
class EgyptGeocodeHit {
  const EgyptGeocodeHit({
    required this.lat,
    required this.lng,
    required this.title,
    this.subtitle = '',
    this.source = 'local',
  });

  final double lat;
  final double lng;
  final String title;
  final String subtitle;
  final String source;
}

/// بحث أماكن لمصر — محلي + Open-Meteo + Photon (+ Google إن توفّر).
/// مصمّم للعمل على Flutter Web بدون CORS proxy.
class EgyptGeocodeService {
  EgyptGeocodeService({
    http.Client? client,
    GoogleMapsApiService? maps,
  })  : _client = client ?? http.Client(),
        _maps = maps ?? GoogleMapsApiService();

  final http.Client _client;
  final GoogleMapsApiService _maps;

  Future<List<EgyptGeocodeHit>> search(
    String query, {
    double? biasLat,
    double? biasLng,
    int limit = 10,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final hits = <EgyptGeocodeHit>[];

    // 1) كتالوج محلي فوري
    for (final p in EgyptPlacesCatalog.search(q, limit: 6)) {
      hits.add(
        EgyptGeocodeHit(
          lat: p.lat,
          lng: p.lng,
          title: p.name,
          subtitle: p.subtitle.isEmpty ? 'مصر' : p.subtitle,
          source: 'local',
        ),
      );
    }

    // 2) Open-Meteo + Photon بالتوازي
    final remote = await Future.wait([
      _searchOpenMeteo(q),
      _searchPhoton(q, biasLat: biasLat, biasLng: biasLng),
      _searchGoogle(q),
    ]);
    for (final list in remote) {
      hits.addAll(list);
    }

    return _dedupe(hits).take(limit).toList();
  }

  Future<List<EgyptGeocodeHit>> _searchOpenMeteo(String query) async {
    try {
      final variants = _variants(query);
      for (final q in variants) {
        final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
          'name': q,
          'count': '8',
          'language': 'ar',
          'format': 'json',
          'countryCode': 'EG',
        });
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) continue;
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final results = body['results'] as List<dynamic>? ?? const [];
        if (results.isEmpty) continue;
        return results.map((raw) {
          final m = raw as Map<String, dynamic>;
          final lat = (m['latitude'] as num?)?.toDouble();
          final lng = (m['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null || !_inEgypt(lat, lng)) return null;
          final name = '${m['name'] ?? q}'.trim();
          final admin = '${m['admin1'] ?? ''}'.trim();
          return EgyptGeocodeHit(
            lat: lat,
            lng: lng,
            title: name.isEmpty ? q : name,
            subtitle: admin.isEmpty ? 'مصر' : '$admin · مصر',
            source: 'open-meteo',
          );
        }).whereType<EgyptGeocodeHit>().toList();
      }
    } catch (e) {
      debugPrint('Open-Meteo geocode failed: $e');
    }
    return const [];
  }

  Future<List<EgyptGeocodeHit>> _searchPhoton(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    try {
      Future<List<EgyptGeocodeHit>> once(Map<String, String> params) async {
        final uri = Uri.https('photon.komoot.io', '/api/', params);
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return const [];
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final features = body['features'] as List<dynamic>? ?? const [];
        final hits = <EgyptGeocodeHit>[];
        for (final raw in features) {
          final f = raw as Map<String, dynamic>;
          final geometry = f['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          if (coords == null || coords.length < 2) continue;
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          if (!_inEgypt(lat, lng)) continue;
          final props = f['properties'] as Map<String, dynamic>? ?? const {};
          final name =
              '${props['name'] ?? props['street'] ?? props['city'] ?? query}'
                  .trim();
          final city = '${props['city'] ?? props['county'] ?? ''}'.trim();
          final state = '${props['state'] ?? ''}'.trim();
          hits.add(
            EgyptGeocodeHit(
              lat: lat,
              lng: lng,
              title: name.isEmpty ? query : name,
              subtitle: [city, state, 'مصر']
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .join(' · '),
              source: 'photon',
            ),
          );
        }
        return hits;
      }

      final base = <String, String>{
        'q': query,
        'limit': '8',
        'lang': 'default',
      };
      if (biasLat != null && biasLng != null) {
        base['lat'] = '$biasLat';
        base['lon'] = '$biasLng';
      }

      var hits = await once(base);
      if (hits.isEmpty) {
        hits = await once({
          ...base,
          'bbox': '24.7,22.0,36.9,31.8',
        });
      }
      return hits;
    } catch (e) {
      debugPrint('Photon geocode failed: $e');
      return const [];
    }
  }

  Future<List<EgyptGeocodeHit>> _searchGoogle(String query) async {
    try {
      final suggestions = await _maps.autocomplete(input: query);
      if (suggestions.isEmpty) return const [];
      final hits = <EgyptGeocodeHit>[];
      for (final s in suggestions.take(5)) {
        try {
          final d = await _maps.placeDetails(placeId: s.placeId);
          if (!_inEgypt(d.latitude, d.longitude)) continue;
          hits.add(
            EgyptGeocodeHit(
              lat: d.latitude,
              lng: d.longitude,
              title: s.mainText.isNotEmpty ? s.mainText : d.formattedAddress,
              subtitle: s.secondaryText.isNotEmpty
                  ? s.secondaryText
                  : d.formattedAddress,
              source: 'google',
            ),
          );
        } catch (_) {
          continue;
        }
      }
      return hits;
    } catch (e) {
      debugPrint('Google geocode failed: $e');
      return const [];
    }
  }

  static List<String> _variants(String raw) {
    final q = raw.trim();
    final n = EgyptPlacesCatalog.normalize(q);
    final swapped = q.endsWith('ه')
        ? '${q.substring(0, q.length - 1)}ة'
        : (q.endsWith('ة') ? '${q.substring(0, q.length - 1)}ه' : q);
    return {
      q,
      n,
      swapped,
      EgyptPlacesCatalog.normalize(swapped),
      if (!q.toLowerCase().contains('egypt') && !q.contains('مصر')) '$q مصر',
    }.where((e) => e.trim().length >= 2).toList();
  }

  static bool _inEgypt(double lat, double lng) =>
      lat >= 21.5 && lat <= 31.8 && lng >= 24.5 && lng <= 37.0;

  static List<EgyptGeocodeHit> _dedupe(List<EgyptGeocodeHit> input) {
    final seen = <String>{};
    final out = <EgyptGeocodeHit>[];
    for (final h in input) {
      final key =
          '${h.title}|${h.lat.toStringAsFixed(3)}|${h.lng.toStringAsFixed(3)}';
      if (seen.add(key)) out.add(h);
    }
    return out;
  }
}
