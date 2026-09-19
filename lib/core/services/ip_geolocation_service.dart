import 'dart:convert';

import 'package:http/http.dart' as http;

/// موقع تقريبي من عنوان الإنترنت — احتياط عندما لا يتوفر GPS.
class IpGeoFix {
  const IpGeoFix({
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.region = '',
    this.countryCode = '',
  });

  final double latitude;
  final double longitude;
  final String city;
  final String region;
  final String countryCode;

  bool get isUsable => latitude != 0 || longitude != 0;
}

class IpGeolocationService {
  IpGeolocationService({http.Client? client}) : _client = client ?? http.Client();

  static final IpGeolocationService instance = IpGeolocationService();

  final http.Client _client;

  static const _timeout = Duration(seconds: 4);

  Future<IpGeoFix?> lookup() async {
    final first = await _tryGet(
      Uri.parse('https://ipwho.is/'),
      parseIpWho,
    );
    if (first != null) return first;
    return _tryGet(
      Uri.parse('https://get.geojs.io/v1/ip/geo.json'),
      parseGeoJs,
    );
  }

  Future<IpGeoFix?> _tryGet(
    Uri uri,
    IpGeoFix? Function(Map<String, dynamic> json) parse,
  ) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final fix = parse(decoded);
      if (fix == null || !fix.isUsable) return null;
      return fix;
    } catch (_) {
      return null;
    }
  }

  static IpGeoFix? parseIpWho(Map<String, dynamic> json) {
    if (json['success'] == false) return null;
    final lat = _toDouble(json['latitude']);
    final lng = _toDouble(json['longitude']);
    if (lat == null || lng == null) return null;
    return IpGeoFix(
      latitude: lat,
      longitude: lng,
      city: (json['city'] as String?)?.trim() ?? '',
      region: (json['region'] as String?)?.trim() ?? '',
      countryCode: (json['country_code'] as String?)?.trim() ?? '',
    );
  }

  static IpGeoFix? parseIpApi(Map<String, dynamic> json) {
    if ((json['status'] as String?) != 'success') return null;
    final lat = _toDouble(json['lat']);
    final lng = _toDouble(json['lon']);
    if (lat == null || lng == null) return null;
    return IpGeoFix(
      latitude: lat,
      longitude: lng,
      city: (json['city'] as String?)?.trim() ?? '',
      region: (json['regionName'] as String?)?.trim() ?? '',
      countryCode: (json['countryCode'] as String?)?.trim() ?? '',
    );
  }

  static IpGeoFix? parseGeoJs(Map<String, dynamic> json) {
    final lat = _toDouble(json['latitude']);
    final lng = _toDouble(json['longitude']);
    if (lat == null || lng == null) return null;
    return IpGeoFix(
      latitude: lat,
      longitude: lng,
      city: (json['city'] as String?)?.trim() ?? '',
      region: (json['region'] as String?)?.trim() ?? '',
      countryCode: (json['country'] as String?)?.trim() ?? '',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
