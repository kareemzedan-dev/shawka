import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_web_places.dart';
import 'package:matlobgo/core/maps/maps_api_key.dart';
import 'package:matlobgo/core/maps/polyline_decoder.dart';
import 'package:matlobgo/core/maps/route_cache.dart';

/// Places Autocomplete + Details + Geocoding + Directions.
class GoogleMapsApiService {
  GoogleMapsApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _cairoBias = '30.0444,31.2357';
  static const _defaultRadiusM = 80000;

  Future<String> _apiKey() async {
    final key = await MapsApiKey.resolve();
    if (key.isEmpty) {
      throw GoogleMapsApiException(
        'maps_api_key_missing',
        message: 'مفتاح الخرائط غير مضبوط. شغّل configure-google-maps.ps1',
      );
    }
    return key;
  }

  /// اقتراحات أماكن (مول، شارع، مستشفى، …).
  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    String? sessionToken,
    LatLng? bias,
  }) async {
    final q = input.trim();
    if (q.length < 2) return const [];

    // على الويب REST API يُحظر بـ CORS — نستخدم Places JS.
    if (kIsWeb) {
      return webPlacesAutocomplete(input: q, sessionToken: sessionToken);
    }

    final key = await _apiKey();
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': q,
          'key': key,
          'language': 'ar',
          'components': 'country:eg',
          'sessiontoken': ?sessionToken,
          'location': bias != null
              ? '${bias.latitude},${bias.longitude}'
              : _cairoBias,
          'radius': '$_defaultRadiusM',
          'strictbounds': 'false',
        });

    final data = await _getJson(uri);
    _throwIfError(data, 'autocomplete');

    final predictions = data['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((p) {
          final map = p as Map<String, dynamic>;
          final structured =
              map['structured_formatting'] as Map<String, dynamic>?;
          return PlaceSuggestion(
            placeId: map['place_id'] as String? ?? '',
            mainText:
                structured?['main_text'] as String? ??
                map['description'] as String? ??
                '',
            secondaryText: structured?['secondary_text'] as String? ?? '',
            fullDescription: map['description'] as String? ?? '',
          );
        })
        .where((s) => s.placeId.isNotEmpty)
        .toList();
  }

  Future<PlaceDetails> placeDetails({
    required String placeId,
    String? sessionToken,
  }) async {
    if (kIsWeb) {
      try {
        return await webPlaceDetails(
          placeId: placeId,
          sessionToken: sessionToken,
        );
      } catch (_) {
        throw GoogleMapsApiException(
          'place_details',
          message: 'تعذّر جلب تفاصيل المكان',
        );
      }
    }

    final key = await _apiKey();
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'key': key,
          'language': 'ar',
          'fields': 'place_id,formatted_address,geometry,address_component',
          'sessiontoken': ?sessionToken,
        });

    final data = await _getJson(uri);
    _throwIfError(data, 'place_details');
    final result = data['result'] as Map<String, dynamic>? ?? {};
    return _parsePlaceDetails(result, placeId);
  }

  /// تحويل الإحداثيات إلى عنوان (موقعي الحالي).
  Future<PlaceDetails> reverseGeocode(LatLng position) async {
    if (kIsWeb) {
      try {
        return await webReverseGeocode(position);
      } catch (_) {
        throw GoogleMapsApiException(
          'geocode',
          message: 'تعذّر تحديد العنوان من الموقع',
        );
      }
    }

    final key = await _apiKey();
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${position.latitude},${position.longitude}',
      'key': key,
      'language': 'ar',
      'region': 'eg',
    });

    final data = await _getJson(uri);
    _throwIfError(data, 'geocode');

    final results = data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      throw GoogleMapsApiException(
        'geocode_empty',
        message: 'تعذّر تحديد العنوان من الموقع',
      );
    }
    return _parsePlaceDetails(results.first as Map<String, dynamic>, '');
  }

  /// مسار على الشوارع (ليس خطاً مستقيماً).
  Future<DirectionsRoute> directions({
    required LatLng origin,
    required LatLng destination,
    bool useCache = true,
  }) async {
    if (useCache) {
      final cached = RouteCache.instance.get(origin, destination);
      if (cached != null) return cached;
    }

    final key = await _apiKey();
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': key,
      'language': 'ar',
      'mode': 'driving',
      'alternatives': 'false',
      'region': 'eg',
    });

    final data = await _getJson(uri);
    _throwIfError(data, 'directions');

    final routes = data['routes'] as List<dynamic>? ?? [];
    if (routes.isEmpty) {
      return DirectionsRoute.empty;
    }

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String? ?? '';
    final legs = route['legs'] as List<dynamic>? ?? [];
    var distanceMeters = 0;
    var durationSeconds = 0;
    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;
      distanceMeters +=
          (legMap['distance'] as Map<String, dynamic>?)?['value'] as int? ?? 0;
      durationSeconds +=
          (legMap['duration'] as Map<String, dynamic>?)?['value'] as int? ?? 0;
    }

    final points = PolylineDecoder.decode(encoded);
    final result = DirectionsRoute(
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: encoded,
    );

    if (result.isValid && useCache) {
      RouteCache.instance.put(origin, destination, result);
    }
    return result;
  }

  PlaceDetails _parsePlaceDetails(Map<String, dynamic> result, String placeId) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble() ?? 0;
    final lng = (location?['lng'] as num?)?.toDouble() ?? 0;

    var area = '';
    var street = '';
    var city = '';
    var governorate = '';
    var countryCode = '';

    final components = result['address_components'] as List<dynamic>? ?? [];
    for (final c in components) {
      final comp = c as Map<String, dynamic>;
      final types = (comp['types'] as List<dynamic>? ?? []).cast<String>();
      final longName = comp['long_name'] as String? ?? '';
      final shortName = comp['short_name'] as String? ?? '';
      if (types.contains('route') || types.contains('street_address')) {
        street = longName;
      } else if (types.contains('sublocality') ||
          types.contains('neighborhood') ||
          types.contains('administrative_area_level_2')) {
        if (area.isEmpty) area = longName;
      } else if (types.contains('locality') ||
          types.contains('administrative_area_level_1')) {
        if (city.isEmpty) city = longName;
        if (types.contains('administrative_area_level_1')) {
          governorate = longName;
        }
      } else if (types.contains('country')) {
        countryCode = shortName.trim().toUpperCase();
      }
    }

    if (governorate.isEmpty && city.isNotEmpty) {
      governorate = city;
    }

    return PlaceDetails(
      placeId: placeId,
      latitude: lat,
      longitude: lng,
      formattedAddress:
          result['formatted_address'] as String? ?? '$area $street'.trim(),
      area: area,
      street: street,
      city: city,
      governorate: governorate,
      countryCode: countryCode,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw GoogleMapsApiException(
          'http_${response.statusCode}',
          message: 'خطأ في الاتصال بخدمة الخرائط',
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, st) {
      if (e is GoogleMapsApiException) rethrow;
      if (kDebugMode) {
        debugPrint('GoogleMapsApiService request failed (${uri.path})');
        debugPrintStack(stackTrace: st);
      }
      throw GoogleMapsApiException(
        'network',
        message: 'تحقق من الاتصال بالإنترنت',
      );
    }
  }

  void _throwIfError(Map<String, dynamic> data, String context) {
    final status = data['status'] as String? ?? 'UNKNOWN';
    if (status == 'OK' || status == 'ZERO_RESULTS') return;
    final msg = data['error_message'] as String? ?? status;
    if (kDebugMode) {
      debugPrint('GoogleMapsApi $context status=$status');
    }
    throw GoogleMapsApiException(
      status,
      message: _friendlyMessage(status, msg),
    );
  }

  static String _friendlyMessage(String status, String _) => switch (status) {
    'REQUEST_DENIED' => 'خدمة الخرائط غير مفعّلة أو المفتاح مقيّد',
    'OVER_QUERY_LIMIT' => 'تم تجاوز حد الطلبات — حاول لاحقاً',
    'INVALID_REQUEST' => 'طلب غير صالح',
    _ => 'تعذّر إكمال طلب الخريطة',
  };
}

class GoogleMapsApiException implements Exception {
  GoogleMapsApiException(this.code, {required this.message});
  final String code;
  final String message;

  @override
  String toString() => message;
}
