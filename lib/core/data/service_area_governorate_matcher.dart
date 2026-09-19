import 'dart:math' as math;

import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/models/store.dart';

/// يطابق نتيجة Reverse Geocoding مع محافظة من الكatalog.
abstract final class ServiceAreaGovernorateMatcher {
  static Governorate? match(String raw, List<Governorate> catalog) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return null;

    for (final g in catalog) {
      final govNorm = _normalize(g.name);
      if (govNorm == normalized) return g;
      if (normalized.contains(govNorm) || govNorm.contains(normalized)) {
        return g;
      }
    }

    for (final entry in _aliasToId.entries) {
      if (normalized.contains(entry.key)) {
        return _byId(catalog, entry.value);
      }
    }

    return null;
  }

  static Governorate? _byId(List<Governorate> catalog, String id) {
    for (final g in catalog) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// أقرب محافظة من الإحداثيات — احتياط عند فشل Reverse Geocoding.
  static Governorate? matchByCoordinates(
    double latitude,
    double longitude,
    List<Governorate> catalog, {
    double maxDistanceKm = 320,
  }) {
    if (latitude == 0 && longitude == 0) return null;
    Governorate? best;
    var bestKm = maxDistanceKm;
    for (final g in catalog) {
      final center = EgyptGovernorates.centerOf(g.id);
      final km = _haversineKm(latitude, longitude, center.lat, center.lng);
      if (km < bestKm) {
        bestKm = km;
        best = g;
      }
    }
    return best;
  }

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthKm = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  static String _normalize(String value) {
    var v = value.trim().toLowerCase();
    const strip = [
      'محافظة',
      'محافظه',
      'governorate',
      'gov.',
      'محافظة ',
    ];
    for (final s in strip) {
      v = v.replaceAll(s.toLowerCase(), '');
    }
    v = v.replaceAll(RegExp(r'\s+'), ' ').trim();
    return v;
  }

  static const Map<String, String> _aliasToId = {
    'cairo': 'cairo',
    'القاهرة': 'cairo',
    'al qahirah': 'cairo',
    'giza': 'giza',
    'الجيزة': 'giza',
    'al jizah': 'giza',
    'alexandria': 'alex',
    'alex': 'alex',
    'الإسكندرية': 'alex',
    'الاسكندرية': 'alex',
    'qalyubia': 'qalyubia',
    'qalyubiyah': 'qalyubia',
    'القليوبية': 'qalyubia',
    'القليوبيه': 'qalyubia',
    'sharqia': 'sharqia',
    'الشرقية': 'sharqia',
    'dakahlia': 'dakahlia',
    'الدقهلية': 'dakahlia',
    'beheira': 'beheira',
    'البحيرة': 'beheira',
    'gharbia': 'gharbia',
    'الغربية': 'gharbia',
    'monufia': 'monufia',
    'المنوفية': 'monufia',
    'kafr el sheikh': 'kafr_el_sheikh',
    'كفر الشيخ': 'kafr_el_sheikh',
    'damietta': 'damietta',
    'دمياط': 'damietta',
    'port said': 'port_said',
    'بورسعيد': 'port_said',
    'ismailia': 'ismailia',
    'الإسماعيلية': 'ismailia',
    'suez': 'suez',
    'suways': 'suez',
    'as suways': 'suez',
    'السويس': 'suez',
    'fayoum': 'fayoum',
    'faiyum': 'fayoum',
    'الفيوم': 'fayoum',
    'beni suef': 'beni_suef',
    'بني سويف': 'beni_suef',
    'minya': 'minya',
    'المنيا': 'minya',
    'asyut': 'asyut',
    'assuit': 'asyut',
    'أسيوط': 'asyut',
    'sohag': 'sohag',
    'سوهاج': 'sohag',
    'qena': 'qena',
    'قنا': 'qena',
    'luxor': 'luxor',
    'الأقصر': 'luxor',
    'aswan': 'aswan',
    'أسوان': 'aswan',
    'red sea': 'red_sea',
    'البحر الأحمر': 'red_sea',
    'new valley': 'new_valley',
    'الوادي الجديد': 'new_valley',
    'matrouh': 'matrouh',
    'مطروح': 'matrouh',
    'north sinai': 'north_sinai',
    'شمال سيناء': 'north_sinai',
    'south sinai': 'south_sinai',
    'جنوب سيناء': 'south_sinai',
  };
}
