import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/maps/directions_route.dart';

Future<List<PlaceSuggestion>> webPlacesAutocomplete({
  required String input,
  String? sessionToken,
}) async =>
    const [];

Future<PlaceDetails> webPlaceDetails({
  required String placeId,
  String? sessionToken,
}) {
  throw UnsupportedError('web places unavailable');
}

Future<PlaceDetails> webReverseGeocode(LatLng position) {
  throw UnsupportedError('web geocode unavailable');
}
