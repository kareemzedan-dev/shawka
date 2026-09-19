import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_web_loader.dart';
import 'package:web/web.dart' as web;

JSObject get _maps {
  final google = web.window.getProperty('google'.toJS) as JSObject;
  return google.getProperty('maps'.toJS) as JSObject;
}

JSObject get _places {
  return _maps.getProperty('places'.toJS) as JSObject;
}

Future<List<PlaceSuggestion>> webPlacesAutocomplete({
  required String input,
  String? sessionToken,
}) async {
  if (!isGoogleMapsJsReady) return const [];
  final q = input.trim();
  if (q.length < 2) return const [];

  final ctor = _places.getProperty('AutocompleteService'.toJS) as JSFunction;
  final service = ctor.callAsConstructor() as JSObject;

  final request = <String, Object?>{
    'input': q,
    'language': 'ar',
    'componentRestrictions': <String, Object?>{'country': 'eg'},
  };
  if (sessionToken != null && sessionToken.isNotEmpty) {
    request['sessionToken'] = sessionToken;
  }

  final completer = Completer<List<PlaceSuggestion>>();
  final callback = ((JSAny? predictions, JSAny? status) {
    final statusStr = (status as JSString?)?.toDart ?? '';
    if (statusStr != 'OK' && statusStr != 'ZERO_RESULTS') {
      completer.complete(const []);
      return;
    }
    final list = <PlaceSuggestion>[];
    final arr = predictions as JSArray?;
    if (arr != null) {
      final length = arr.length;
      for (var i = 0; i < length; i++) {
        final p = arr.getProperty(i.toJS) as JSObject;
        final structured =
            p.getProperty('structured_formatting'.toJS) as JSObject?;
        list.add(
          PlaceSuggestion(
            placeId: _str(p, 'place_id'),
            mainText: structured != null
                ? _str(structured, 'main_text')
                : _str(p, 'description'),
            secondaryText: structured != null
                ? _str(structured, 'secondary_text')
                : '',
            fullDescription: _str(p, 'description'),
          ),
        );
      }
    }
    completer.complete(list.where((s) => s.placeId.isNotEmpty).toList());
  }).toJS;

  service.callMethod('getPlacePredictions'.toJS, request.jsify(), callback);
  return completer.future.timeout(
    const Duration(seconds: 12),
    onTimeout: () => const [],
  );
}

Future<PlaceDetails> webPlaceDetails({
  required String placeId,
  String? sessionToken,
}) async {
  if (!isGoogleMapsJsReady) {
    throw StateError('Google Maps JS غير جاهز');
  }

  final attr = web.document.createElement('div');
  final ctor = _places.getProperty('PlacesService'.toJS) as JSFunction;
  final service = ctor.callAsConstructor(attr) as JSObject;

  final request = <String, Object?>{
    'placeId': placeId,
    'fields': <String>[
      'place_id',
      'formatted_address',
      'geometry',
      'address_component',
    ],
    'language': 'ar',
  };
  if (sessionToken != null && sessionToken.isNotEmpty) {
    request['sessionToken'] = sessionToken;
  }

  final completer = Completer<PlaceDetails>();
  final callback = ((JSAny? place, JSAny? status) {
    final statusStr = (status as JSString?)?.toDart ?? '';
    if (statusStr != 'OK' || place == null) {
      completer.completeError(StateError('place_details_$statusStr'));
      return;
    }
    try {
      completer.complete(_parseJsPlace(place as JSObject, placeId));
    } catch (e) {
      completer.completeError(e);
    }
  }).toJS;

  service.callMethod('getDetails'.toJS, request.jsify(), callback);
  return completer.future.timeout(const Duration(seconds: 12));
}

Future<PlaceDetails> webReverseGeocode(LatLng position) async {
  if (!isGoogleMapsJsReady) {
    throw StateError('Google Maps JS غير جاهز');
  }

  final ctor = _maps.getProperty('Geocoder'.toJS) as JSFunction;
  final geocoder = ctor.callAsConstructor() as JSObject;

  final request = <String, Object?>{
    'location': <String, Object?>{
      'lat': position.latitude,
      'lng': position.longitude,
    },
    'language': 'ar',
  }.jsify();

  final completer = Completer<PlaceDetails>();
  final callback = ((JSAny? results, JSAny? status) {
    final statusStr = (status as JSString?)?.toDart ?? '';
    final arr = results as JSArray?;
    if (statusStr != 'OK' || arr == null || arr.length == 0) {
      completer.completeError(StateError('geocode_$statusStr'));
      return;
    }
    try {
      completer.complete(
        _parseJsPlace(arr.getProperty(0.toJS) as JSObject, ''),
      );
    } catch (e) {
      completer.completeError(e);
    }
  }).toJS;

  geocoder.callMethod('geocode'.toJS, request, callback);
  return completer.future.timeout(const Duration(seconds: 12));
}

PlaceDetails _parseJsPlace(JSObject place, String fallbackId) {
  final geometry = place.getProperty('geometry'.toJS) as JSObject;
  final location = geometry.getProperty('location'.toJS) as JSObject;
  final lat = _latLngNumber(location, 'lat');
  final lng = _latLngNumber(location, 'lng');

  return PlaceDetails(
    placeId: _str(place, 'place_id').isEmpty
        ? fallbackId
        : _str(place, 'place_id'),
    latitude: lat,
    longitude: lng,
    formattedAddress: _str(place, 'formatted_address'),
    area: '',
    street: '',
    city: '',
    governorate: '',
  );
}

double _latLngNumber(JSObject location, String name) {
  final prop = location.getProperty(name.toJS);
  if (prop is JSFunction) {
    final value = prop.callAsFunction(location);
    return (value as JSNumber).toDartDouble;
  }
  if (prop is JSNumber) return prop.toDartDouble;
  return double.parse('$prop');
}

String _str(JSObject obj, String key) {
  final v = obj.getProperty(key.toJS);
  if (v == null) return '';
  if (v is JSString) return v.toDart;
  return '$v';
}
