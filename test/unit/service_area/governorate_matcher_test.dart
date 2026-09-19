import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/data/service_area_governorate_matcher.dart';

void main() {
  final catalog = EgyptGovernorates.all;

  group('ServiceAreaGovernorateMatcher.match', () {
    test('matches Arabic governorate names', () {
      expect(
        ServiceAreaGovernorateMatcher.match('القاهرة', catalog)?.id,
        'cairo',
      );
      expect(
        ServiceAreaGovernorateMatcher.match('محافظة الجيزة', catalog)?.id,
        'giza',
      );
    });

    test('matches English aliases', () {
      expect(
        ServiceAreaGovernorateMatcher.match('Cairo Governorate', catalog)?.id,
        'cairo',
      );
      expect(
        ServiceAreaGovernorateMatcher.match('Alexandria', catalog)?.id,
        'alex',
      );
    });
  });

  group('ServiceAreaGovernorateMatcher.matchByCoordinates', () {
    test('maps downtown Cairo to cairo', () {
      expect(
        ServiceAreaGovernorateMatcher.matchByCoordinates(
          30.0444,
          31.2357,
          catalog,
        )?.id,
        'cairo',
      );
    });

    test('maps Giza pyramids area to giza', () {
      expect(
        ServiceAreaGovernorateMatcher.matchByCoordinates(
          29.9773,
          31.1325,
          catalog,
        )?.id,
        'giza',
      );
    });

    test('maps Alexandria corniche to alex', () {
      expect(
        ServiceAreaGovernorateMatcher.matchByCoordinates(
          31.2156,
          29.9553,
          catalog,
        )?.id,
        'alex',
      );
    });

    test('maps Qalyubia / Banha to qalyubia', () {
      expect(
        ServiceAreaGovernorateMatcher.matchByCoordinates(
          30.466,
          31.184,
          catalog,
        )?.id,
        'qalyubia',
      );
    });

    test('ignores null island', () {
      expect(
        ServiceAreaGovernorateMatcher.matchByCoordinates(0, 0, catalog),
        isNull,
      );
    });

    test('returns null far outside Egypt', () {
      expect(
        ServiceAreaGovernorateMatcher.matchByCoordinates(
          51.5074,
          -0.1278,
          catalog,
        ),
        isNull,
      );
    });
  });
}
