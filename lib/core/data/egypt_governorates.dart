import 'package:matlobgo/models/store.dart';

/// محافظات مصر — مشتركة بين العميل ولوحة التحكم.
abstract final class EgyptGovernorates {
  static const List<Governorate> all = [
    Governorate(id: 'cairo', name: 'القاهرة', isAvailable: true),
    Governorate(id: 'giza', name: 'الجيزة', isAvailable: true),
    Governorate(id: 'alex', name: 'الإسكندرية', isAvailable: true),
    Governorate(id: 'qalyubia', name: 'القليوبية', isAvailable: true),
    Governorate(id: 'sharqia', name: 'الشرقية', isAvailable: false),
    Governorate(id: 'dakahlia', name: 'الدقهلية', isAvailable: false),
    Governorate(id: 'beheira', name: 'البحيرة', isAvailable: false),
    Governorate(id: 'gharbia', name: 'الغربية', isAvailable: false),
    Governorate(id: 'monufia', name: 'المنوفية', isAvailable: false),
    Governorate(id: 'kafr_el_sheikh', name: 'كفر الشيخ', isAvailable: false),
    Governorate(id: 'damietta', name: 'دمياط', isAvailable: false),
    Governorate(id: 'port_said', name: 'بورسعيد', isAvailable: false),
    Governorate(id: 'ismailia', name: 'الإسماعيلية', isAvailable: false),
    Governorate(id: 'suez', name: 'السويس', isAvailable: false),
    Governorate(id: 'fayoum', name: 'الفيوم', isAvailable: false),
    Governorate(id: 'beni_suef', name: 'بني سويف', isAvailable: false),
    Governorate(id: 'minya', name: 'المنيا', isAvailable: false),
    Governorate(id: 'asyut', name: 'أسيوط', isAvailable: false),
    Governorate(id: 'sohag', name: 'سوهاج', isAvailable: false),
    Governorate(id: 'qena', name: 'قنا', isAvailable: false),
    Governorate(id: 'luxor', name: 'الأقصر', isAvailable: false),
    Governorate(id: 'aswan', name: 'أسوان', isAvailable: false),
    Governorate(id: 'red_sea', name: 'البحر الأحمر', isAvailable: false),
    Governorate(id: 'new_valley', name: 'الوادي الجديد', isAvailable: false),
    Governorate(id: 'matrouh', name: 'مطروح', isAvailable: false),
    Governorate(id: 'north_sinai', name: 'شمال سيناء', isAvailable: false),
    Governorate(id: 'south_sinai', name: 'جنوب سيناء', isAvailable: false),
  ];

  static List<Governorate> get available =>
      all.where((g) => g.isAvailable).toList();

  static Governorate get defaultGovernorate => available.first;

  static Governorate? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }

  static Governorate? byName(String name) {
    for (final g in all) {
      if (g.name == name) return g;
    }
    return null;
  }

  /// مركز تقريبي للمحافظة — fallback عند فشل GPS أو غياب إحداثيات المتجر.
  static ({double lat, double lng}) centerOf(String id) {
    return switch (id) {
      'cairo' => (lat: 30.0444, lng: 31.2357),
      'giza' => (lat: 30.0131, lng: 31.2089),
      'alex' => (lat: 31.2001, lng: 29.9187),
      'qalyubia' => (lat: 30.3292, lng: 31.2169),
      'sharqia' => (lat: 30.5877, lng: 31.5020),
      'dakahlia' => (lat: 31.0409, lng: 31.3785),
      'beheira' => (lat: 30.8481, lng: 30.3436),
      'gharbia' => (lat: 30.8754, lng: 31.0335),
      'monufia' => (lat: 30.5972, lng: 30.9876),
      'kafr_el_sheikh' => (lat: 31.1107, lng: 30.9388),
      'damietta' => (lat: 31.4165, lng: 31.8133),
      'port_said' => (lat: 31.2653, lng: 32.3019),
      'ismailia' => (lat: 30.5965, lng: 32.2715),
      'suez' => (lat: 29.9668, lng: 32.5498),
      'fayoum' => (lat: 29.3084, lng: 30.8428),
      'beni_suef' => (lat: 29.0661, lng: 31.0994),
      'minya' => (lat: 28.1099, lng: 30.7503),
      'asyut' => (lat: 27.1809, lng: 31.1837),
      'sohag' => (lat: 26.5590, lng: 31.6957),
      'qena' => (lat: 26.1551, lng: 32.7160),
      'luxor' => (lat: 25.6872, lng: 32.6396),
      'aswan' => (lat: 24.0889, lng: 32.8998),
      'red_sea' => (lat: 27.2579, lng: 33.8116),
      'new_valley' => (lat: 25.4514, lng: 30.5463),
      'matrouh' => (lat: 31.3543, lng: 27.2373),
      'north_sinai' => (lat: 31.1313, lng: 33.8012),
      'south_sinai' => (lat: 28.2369, lng: 33.6253),
      _ => (lat: 30.0444, lng: 31.2357),
    };
  }

  static ({double lat, double lng}) centerOfGovernorate(Governorate governorate) =>
      centerOf(governorate.id);
}
