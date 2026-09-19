import 'package:matlobgo/core/data/egypt_governorates.dart';

/// أماكن مصر للبحث المحلي في لوحة التحكم (بدون اعتماد على شبكة).
class EgyptPlaceHit {
  const EgyptPlaceHit({
    required this.name,
    required this.lat,
    required this.lng,
    this.subtitle = '',
    this.aliases = const [],
  });

  final String name;
  final double lat;
  final double lng;
  final String subtitle;
  final List<String> aliases;
}

abstract final class EgyptPlacesCatalog {
  static final List<EgyptPlaceHit> all = [
    for (final g in EgyptGovernorates.all)
      EgyptPlaceHit(
        name: g.name,
        lat: EgyptGovernorates.centerOf(g.id).lat,
        lng: EgyptGovernorates.centerOf(g.id).lng,
        subtitle: 'محافظة',
        aliases: _aliasesFor(g.id),
      ),
    // أحياء ومناطق شائعة
    const EgyptPlaceHit(
      name: 'مدينة نصر',
      lat: 30.0511,
      lng: 31.3656,
      subtitle: 'القاهرة',
      aliases: ['nasr city', 'مدينه نصر'],
    ),
    const EgyptPlaceHit(
      name: 'المعادي',
      lat: 29.9602,
      lng: 31.2569,
      subtitle: 'القاهرة',
      aliases: ['maadi', 'المعادي'],
    ),
    const EgyptPlaceHit(
      name: 'مصر الجديدة',
      lat: 30.1000,
      lng: 31.3300,
      subtitle: 'القاهرة',
      aliases: ['heliopolis', 'مصر الجديده', 'هيليوبوليس'],
    ),
    const EgyptPlaceHit(
      name: 'الزمالك',
      lat: 30.0611,
      lng: 31.2197,
      subtitle: 'القاهرة',
      aliases: ['zamalek'],
    ),
    const EgyptPlaceHit(
      name: 'وسط البلد',
      lat: 30.0444,
      lng: 31.2357,
      subtitle: 'القاهرة',
      aliases: ['downtown', 'وسط القاهره', 'التحرير'],
    ),
    const EgyptPlaceHit(
      name: 'حدائق الأهرام',
      lat: 29.9833,
      lng: 31.1333,
      subtitle: 'الجيزة',
      aliases: ['hadayek al ahram', 'الاهرام'],
    ),
    const EgyptPlaceHit(
      name: 'الشيخ زايد',
      lat: 30.0270,
      lng: 30.9780,
      subtitle: 'الجيزة',
      aliases: ['sheikh zayed', 'زايد'],
    ),
    const EgyptPlaceHit(
      name: '6 أكتوبر',
      lat: 29.9285,
      lng: 30.9188,
      subtitle: 'الجيزة',
      aliases: ['6 october', 'اكتوبر', 'أكتوبر'],
    ),
    const EgyptPlaceHit(
      name: 'المنطقة الصناعية',
      lat: 29.0744,
      lng: 31.0979,
      subtitle: 'بني سويف',
      aliases: ['بني سويف الصناعية'],
    ),
  ];

  static List<String> _aliasesFor(String id) => switch (id) {
        'cairo' => ['cairo', 'القاهره', 'قاهرة', 'قاهره'],
        'giza' => ['giza', 'الجيزه', 'جيزة', 'جيزه'],
        'alex' => ['alexandria', 'اسكندرية', 'اسكندريه', 'إسكندرية'],
        'beni_suef' => ['bani suef', 'beni suef', 'بنى سويف', 'بنيسويف'],
        'qalyubia' => ['qalyubia', 'القليوبيه'],
        'sharqia' => ['sharqia', 'الشرقيه'],
        'dakahlia' => ['dakahlia', 'الدقهليه'],
        'gharbia' => ['gharbia', 'الغربيه'],
        'monufia' => ['monufia', 'المنوفيه'],
        'fayoum' => ['fayoum', 'الفيوم'],
        'minya' => ['minya', 'المنيا'],
        'asyut' => ['asyut', 'اسيوط', 'أسيوط'],
        'sohag' => ['sohag', 'سوهاج'],
        'luxor' => ['luxor', 'الاقصر', 'الأقصر'],
        'aswan' => ['aswan', 'اسوان', 'أسوان'],
        _ => const [],
      };

  static String normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<EgyptPlaceHit> search(String query, {int limit = 8}) {
    final q = normalize(query);
    if (q.isEmpty) return const [];

    final tokens = q.split(' ').where((t) => t.isNotEmpty).toList();
    final scored = <({EgyptPlaceHit hit, int score})>[];
    for (final place in all) {
      final name = normalize(place.name);
      final aliases = place.aliases.map(normalize).toList();
      final haystack = [name, ...aliases].join(' | ');

      int score = 0;
      if (name == q || aliases.contains(q)) {
        score = 100;
      } else if (name.startsWith(q) || aliases.any((a) => a.startsWith(q))) {
        score = 90;
      } else if (haystack.contains(q)) {
        score = 80;
      } else if (q.contains(name) && name.length >= 3) {
        score = 70;
      } else if (tokens.length >= 2 &&
          tokens.every((t) => t.length >= 2 && haystack.contains(t))) {
        // "beni suef" → كل كلمة تطابق alias
        score = 85;
      } else if (tokens.any((t) => t.length >= 3 && haystack.contains(t))) {
        score = 55;
      }
      if (score > 0) scored.add((hit: place, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.hit).toList();
  }
}
