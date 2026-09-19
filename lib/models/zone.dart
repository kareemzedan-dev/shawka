import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// منطقة خدمة داخل محافظة.
class ServiceZone {
  const ServiceZone({
    required this.id,
    required this.governorateId,
    required this.name,
    required this.polygon,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String governorateId;
  final String name;
  final List<LatLng> polygon;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ServiceZone.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String governorateId,
  }) {
    final data = doc.data() ?? {};
    final rawPolygon = data['polygon'] as List<dynamic>? ?? [];
    final polygon = rawPolygon.map((p) {
      final m = p as Map<String, dynamic>;
      return LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      );
    }).toList();

    return ServiceZone(
      id: doc.id,
      governorateId: governorateId,
      name: data['name'] as String? ?? '',
      polygon: polygon,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'governorateId': governorateId,
      'name': name,
      'polygon': polygon
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ServiceZone copyWith({
    String? governorateId,
    String? name,
    List<LatLng>? polygon,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceZone(
      id: id,
      governorateId: governorateId ?? this.governorateId,
      name: name ?? this.name,
      polygon: polygon ?? this.polygon,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool containsPoint(LatLng point) {
    if (polygon.length < 3) return false;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].latitude, yi = polygon[i].longitude;
      final xj = polygon[j].latitude, yj = polygon[j].longitude;
      final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude <
              (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ServiceZone && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
