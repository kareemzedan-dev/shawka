/// شريحة تسعير التوصيل حسب مسافة الطريق (كم).
class DeliveryPricingTier {
  const DeliveryPricingTier({
    required this.minKm,
    required this.maxKm,
    required this.fee,
  });

  final double minKm;
  final double maxKm;
  final double fee;

  static const List<DeliveryPricingTier> defaults = [
    DeliveryPricingTier(minKm: 0, maxKm: 3, fee: 15),
    DeliveryPricingTier(minKm: 3, maxKm: 7, fee: 25),
    DeliveryPricingTier(minKm: 7, maxKm: 10, fee: 35),
    DeliveryPricingTier(minKm: 10, maxKm: 15, fee: 50),
  ];

  factory DeliveryPricingTier.fromMap(Map<String, dynamic> map) {
    return DeliveryPricingTier(
      minKm: (map['minKm'] as num?)?.toDouble() ?? 0,
      maxKm: (map['maxKm'] as num?)?.toDouble() ?? 0,
      fee: (map['fee'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'minKm': minKm,
        'maxKm': maxKm,
        'fee': fee,
      };

  DeliveryPricingTier copyWith({
    double? minKm,
    double? maxKm,
    double? fee,
  }) {
    return DeliveryPricingTier(
      minKm: minKm ?? this.minKm,
      maxKm: maxKm ?? this.maxKm,
      fee: fee ?? this.fee,
    );
  }

  static List<DeliveryPricingTier> parseList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    final tiers = raw
        .whereType<Map>()
        .map((e) => DeliveryPricingTier.fromMap(Map<String, dynamic>.from(e)))
        .where((t) => t.maxKm > t.minKm)
        .toList();
    if (tiers.isEmpty) return defaults;
    tiers.sort((a, b) => a.minKm.compareTo(b.minKm));
    return tiers;
  }
}

class DeliveryTierResult {
  const DeliveryTierResult({
    required this.fee,
    required this.isDeliverable,
  });

  const DeliveryTierResult.outOfZone()
      : fee = 0,
        isDeliverable = false;

  final double fee;
  final bool isDeliverable;

  static DeliveryTierResult resolve({
    required double roadDistanceKm,
    required List<DeliveryPricingTier> tiers,
    required double maxRoadKm,
  }) {
    if (roadDistanceKm <= 0) {
      return const DeliveryTierResult.outOfZone();
    }
    if (roadDistanceKm > maxRoadKm) {
      return const DeliveryTierResult.outOfZone();
    }

    final sorted = [...tiers]..sort((a, b) => a.minKm.compareTo(b.minKm));
    for (var i = 0; i < sorted.length; i++) {
      final tier = sorted[i];
      final isFirst = i == 0;
      final inRange = isFirst
          ? roadDistanceKm >= tier.minKm && roadDistanceKm <= tier.maxKm
          : roadDistanceKm > tier.minKm && roadDistanceKm <= tier.maxKm;
      if (inRange) {
        return DeliveryTierResult(fee: tier.fee, isDeliverable: true);
      }
    }
    return const DeliveryTierResult.outOfZone();
  }
}

class StoreDeliveryQuoteLine {
  const StoreDeliveryQuoteLine({
    required this.storeId,
    required this.storeName,
    required this.distanceKm,
    required this.fee,
    required this.isDeliverable,
  });

  final String storeId;
  final String storeName;
  final double distanceKm;
  final double fee;
  final bool isDeliverable;
}
