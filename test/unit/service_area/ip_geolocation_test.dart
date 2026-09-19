import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/data/service_area_governorate_matcher.dart';
import 'package:matlobgo/core/services/ip_geolocation_service.dart';

void main() {
  final catalog = EgyptGovernorates.all;

  test('parses ipwho.is Cairo payload', () {
    final fix = IpGeolocationService.parseIpWho({
      'success': true,
      'city': 'Cairo',
      'region': 'Cairo Governorate',
      'country_code': 'EG',
      'latitude': 30.0444,
      'longitude': 31.2357,
    });
    expect(fix, isNotNull);
    expect(
      ServiceAreaGovernorateMatcher.match(fix!.region, catalog)?.id,
      'cairo',
    );
    expect(
      ServiceAreaGovernorateMatcher.matchByCoordinates(
        fix.latitude,
        fix.longitude,
        catalog,
      )?.id,
      'cairo',
    );
  });

  test('parses geojs string coordinates for Giza', () {
    final fix = IpGeolocationService.parseGeoJs({
      'city': 'Giza',
      'region': 'Giza',
      'country': 'EG',
      'latitude': '30.0131',
      'longitude': '31.2089',
    });
    expect(fix, isNotNull);
    expect(
      ServiceAreaGovernorateMatcher.match(fix!.city, catalog)?.id,
      'giza',
    );
  });
}
