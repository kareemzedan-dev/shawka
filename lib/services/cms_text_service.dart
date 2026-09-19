import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/cms/cms_text_format.dart';
import 'package:matlobgo/repositories/cms_text_repository.dart';
import 'package:matlobgo/services/app_config_service.dart';

/// نصوص CMS حية — أي تعديل من لوحة التحكم يظهر فوراً.
class CmsTextService extends ChangeNotifier {
  CmsTextService._();

  static final CmsTextService instance = CmsTextService._();

  final _repo = CmsTextRepository();
  Map<String, String> _texts = {};

  Map<String, String> get texts => Map.unmodifiable(_texts);

  Future<void> start() async {
    _repo.watchTextMap().listen((map) {
      _texts = map;
      notifyListeners();
    }, onError: (_) {});

    // Seeding requires admin write access; never block app startup on failure.
    unawaited(_seedDefaultsSafely());
  }

  Future<void> _seedDefaultsSafely() async {
    try {
      await _repo.seedDefaultsIfEmpty();
      await _repo.ensureDefaultKeys();
    } catch (_) {}
  }

  String resolve(String key, {required String fallback}) {
    final v = _texts[key]?.trim();
    return v != null && v.isNotEmpty ? v : fallback;
  }

  String interpolate(
    String template, {
    String? name,
    String? city,
    String? time,
  }) => interpolateCmsTemplate(template, name: name, city: city, time: time);

  /// ترحيب — CMS أولاً ثم إعدادات التطبيق.
  String welcomeMessage({required bool isGuest, required String userName}) {
    final settings = AppConfigService.instance.settings;
    if (isGuest) {
      return resolve(
        CmsKeys.welcomeGuest,
        fallback: settings.resolveWelcomeMessage(
          isGuest: true,
          userName: userName,
        ),
      );
    }
    final tpl = resolve(
      CmsKeys.welcomeUser,
      fallback: settings.welcomeMessage.trim().isNotEmpty
          ? settings.welcomeMessage
          : 'أهلاً {name} 👋',
    );
    return interpolate(tpl, name: userName);
  }

  String promoHint({String fallback = 'استخدم كود الخصم في السلة'}) =>
      resolve(CmsKeys.promoHint, fallback: fallback);

  String homeSearchHint({String fallback = ''}) {
    final legacy = resolve(CmsKeys.homeSearchHint, fallback: fallback);
    return resolve(CmsKeys.searchPlaceholder, fallback: legacy);
  }

  String searchPageTitle({String fallback = ''}) =>
      resolve(CmsKeys.searchPageTitle, fallback: fallback);

  String searchPopularTitle({String fallback = ''}) =>
      resolve(CmsKeys.searchPopularTitle, fallback: fallback);

  String searchRecentTitle({String fallback = ''}) =>
      resolve(CmsKeys.searchRecentTitle, fallback: fallback);

  String searchRecentClear({String fallback = ''}) =>
      resolve(CmsKeys.searchRecentClear, fallback: fallback);

  String searchFilterAll({String fallback = ''}) =>
      resolve(CmsKeys.searchFilterAll, fallback: fallback);

  String searchSuggestedStoresTitle({String fallback = ''}) =>
      resolve(CmsKeys.searchSuggestedStoresTitle, fallback: fallback);

  String searchSuggestedStoresSubtitle({String fallback = ''}) =>
      resolve(CmsKeys.searchSuggestedStoresSubtitle, fallback: fallback);

  String homeMostOrderedTitle({String fallback = 'الأكثر طلباً'}) =>
      resolve(CmsKeys.homeMostOrderedTitle, fallback: fallback);

  String homeBestSellingTitle({String fallback = 'الأكثر مبيعًا 🔥'}) =>
      resolve(CmsKeys.homeBestSellingTitle, fallback: fallback);

  String homeOffersLabel({String fallback = 'عروض'}) =>
      resolve(CmsKeys.homeOffersLabel, fallback: fallback);

  String homeTrackOrderLabel({String fallback = 'تفاصيل'}) =>
      resolve(CmsKeys.homeTrackOrder, fallback: fallback);

  String homeFreeDeliveryLabel({String fallback = 'توصيل مجاني'}) =>
      resolve(CmsKeys.homeFreeDelivery, fallback: fallback);

  String homeViewAllLabel({String fallback = 'عرض الكل'}) =>
      resolve(CmsKeys.homeViewAll, fallback: fallback);

  static const _defaultHomeSearchHints = [
    '📦 ابحث عن مورد',
    '🛒 ابحث عن منتجات',
    '🥫 ابحث عن مواد غذائية',
    '🚚 اطلب أي شيء',
  ];

  /// تلميحات شريط البحث في الرئيسية — افصل بينها بـ `|` في CMS.
  /// إن وُجد تلميح واحد فقط نستخدم القائمة الافتراضية حتى يدور النص.
  List<String> homeSearchHints() {
    final fromCms = parseCmsPipeList(
      homeSearchHint(fallback: ''),
      fallback: const [],
    );
    if (fromCms.length > 1) return fromCms;
    return _defaultHomeSearchHints;
  }

  String timeGreeting(DateTime now, {String? city}) {
    final isMorning = now.hour < 17;
    final greeting = resolve(
      isMorning ? CmsKeys.greetingMorning : CmsKeys.greetingEvening,
      fallback: isMorning ? 'صباح الخير' : 'مساء الخير',
    );
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final seasonal = resolve(CmsKeys.greetingSeasonal, fallback: '');
    final value = seasonal.isEmpty ? greeting : '$greeting $seasonal';
    return interpolate(value, city: city?.trim(), time: time).trim();
  }

  String guestHeadline({String fallback = 'ماذا ترغب أن تطلب اليوم؟'}) =>
      resolve(CmsKeys.greetingGuestHeadline, fallback: fallback);

  List<String> searchSuggestions() =>
      _pipeList(CmsKeys.searchSuggestions, fallback: const []);

  List<String> searchTrending() =>
      _pipeList(CmsKeys.searchTrending, fallback: const []);

  List<String> searchBlacklist() =>
      _pipeList(CmsKeys.searchBlacklist, fallback: const []);

  List<String> _pipeList(String key, {required List<String> fallback}) =>
      parseCmsPipeList(resolve(key, fallback: ''), fallback: fallback);
}
