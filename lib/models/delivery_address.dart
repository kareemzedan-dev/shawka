import 'package:google_maps_flutter/google_maps_flutter.dart';

/// عنوان توصيل مُتحقق منه بإحداثيات GPS.
class DeliveryAddress {
  const DeliveryAddress({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.area = '',
    this.street = '',
    this.placeId = '',
    this.label = '',
    this.buildingNotes = '',
    this.governorate = '',
    this.isValid = true,
    this.outOfZone = false,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String area;
  final String street;
  final String placeId;
  final String label;
  final String buildingNotes;
  final String governorate;
  final bool isValid;
  final bool outOfZone;

  LatLng get latLng => LatLng(latitude, longitude);

  bool get hasCoordinates =>
      latitude != 0 && longitude != 0 && isValid && !outOfZone;

  String get displayLine {
    if (formattedAddress.trim().isNotEmpty) return formattedAddress.trim();
    final parts = [area, street].where((e) => e.trim().isNotEmpty);
    return parts.join(' — ');
  }

  String get shortLine {
    if (street.trim().isNotEmpty && area.trim().isNotEmpty) {
      return '$area · $street';
    }
    return displayLine;
  }

  /// نص يُحفظ في الطلب (متوافق مع العرض القديم).
  String get legacyAddressText {
    final base = displayLine;
    if (buildingNotes.trim().isEmpty) return base;
    return '$base\n${buildingNotes.trim()}';
  }

  Map<String, dynamic> toOrderFields() => {
        'address': legacyAddressText,
        'addressLat': latitude,
        'addressLng': longitude,
        if (placeId.isNotEmpty) 'addressPlaceId': placeId,
        if (area.isNotEmpty) 'addressArea': area,
        if (street.isNotEmpty) 'addressStreet': street,
        if (formattedAddress.isNotEmpty) 'addressFormatted': formattedAddress,
      };

  factory DeliveryAddress.fromPlaceDetails({
    required double latitude,
    required double longitude,
    required String formattedAddress,
    String area = '',
    String street = '',
    String placeId = '',
    String governorate = '',
    String buildingNotes = '',
    String label = '',
    bool outOfZone = false,
  }) {
    final hasCoords = latitude != 0 && longitude != 0;
    return DeliveryAddress(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: formattedAddress,
      area: area,
      street: street,
      placeId: placeId,
      governorate: governorate,
      buildingNotes: buildingNotes,
      label: label,
      isValid: hasCoords && !outOfZone,
      outOfZone: outOfZone,
    );
  }

  factory DeliveryAddress.fromFirestore(Map<String, dynamic> data) {
    return DeliveryAddress(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      formattedAddress: data['formattedAddress'] as String? ?? '',
      area: data['area'] as String? ?? '',
      street: data['street'] as String? ?? '',
      placeId: data['placeId'] as String? ?? '',
      label: data['label'] as String? ?? '',
      buildingNotes: data['buildingNotes'] as String? ?? '',
      governorate: data['governorate'] as String? ?? '',
      isValid: data['isValid'] as bool? ?? true,
      outOfZone: data['outOfZone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'latitude': latitude,
        'longitude': longitude,
        'formattedAddress': formattedAddress,
        'area': area,
        'street': street,
        'placeId': placeId,
        'label': label,
        'buildingNotes': buildingNotes,
        'governorate': governorate,
        'isValid': isValid,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  DeliveryAddress copyWith({
    String? buildingNotes,
    String? label,
    bool? outOfZone,
  }) {
    return DeliveryAddress(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: formattedAddress,
      area: area,
      street: street,
      placeId: placeId,
      label: label ?? this.label,
      buildingNotes: buildingNotes ?? this.buildingNotes,
      governorate: governorate,
      isValid: isValid,
      outOfZone: outOfZone ?? this.outOfZone,
    );
  }
}

enum SavedAddressLabel {
  home,
  work,
  other;

  String get firestoreValue => name;

  String get displayName => switch (this) {
        SavedAddressLabel.home => 'المنزل',
        SavedAddressLabel.work => 'العمل',
        SavedAddressLabel.other => 'عنوان آخر',
      };

  String get icon => switch (this) {
        SavedAddressLabel.home => '🏠',
        SavedAddressLabel.work => '💼',
        SavedAddressLabel.other => '📍',
      };

  static SavedAddressLabel fromFirestore(String? v) {
    return SavedAddressLabel.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SavedAddressLabel.other,
    );
  }
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    this.isDefault = false,
  });

  final String id;
  final SavedAddressLabel label;
  final DeliveryAddress address;
  final bool isDefault;

  factory SavedAddress.fromFirestore(String id, Map<String, dynamic> data) {
    return SavedAddress(
      id: id,
      label: SavedAddressLabel.fromFirestore(data['label'] as String?),
      address: DeliveryAddress.fromFirestore(data),
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'label': label.firestoreValue,
        ...address.toFirestore(),
        'isDefault': isDefault,
      };
}
