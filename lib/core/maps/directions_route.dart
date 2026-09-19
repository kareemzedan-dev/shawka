import 'package:google_maps_flutter/google_maps_flutter.dart';

/// مسار من Google Directions API.
class DirectionsRoute {
  const DirectionsRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.encodedPolyline = '',
  });

  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;

  double get distanceKm => distanceMeters / 1000.0;

  int get durationMinutes => (durationSeconds / 60).ceil().clamp(1, 999);

  static const empty = DirectionsRoute(
    points: [],
    distanceMeters: 0,
    durationSeconds: 0,
  );

  bool get isValid => points.length >= 2 && distanceMeters > 0;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullDescription,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullDescription;
}

class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.area = '',
    this.street = '',
    this.city = '',
    this.governorate = '',
    this.countryCode = '',
  });

  final String placeId;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String area;
  final String street;
  final String city;
  final String governorate;

  /// ISO country code إن توفر من reverse geocode (مثل EG).
  final String countryCode;

  LatLng get latLng => LatLng(latitude, longitude);
}
