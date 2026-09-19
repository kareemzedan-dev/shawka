import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/domain/usecases/watch_app_settings_use_case.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/promo_banner_record.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/promo_banner_repository.dart';

/// إعدادات ومحتوى التطبيق — Domain Use Cases + كاش Firestore.
class AppConfigService extends ChangeNotifier {
  AppConfigService._();

  static final AppConfigService instance = AppConfigService._();

  final _bannerRepo = PromoBannerRepository();
  WatchAppSettingsUseCase get _watchSettings => ServiceLocator.watchAppSettings;
  WatchGovernoratesUseCase get _watchGovernorates =>
      ServiceLocator.watchGovernorates;

  AppSettings _settings = const AppSettings();
  StreamSubscription<AppSettings>? _settingsSub;

  AppSettings get settings => _settings;

  void start() {
    _settingsSub?.cancel();
    _settingsSub = _watchSettings.call().listen((s) {
      _settings = s;
      notifyListeners();
    }, onError: (_) {});
  }

  void stop() {
    _settingsSub?.cancel();
    _settingsSub = null;
  }

  Stream<List<Governorate>> watchGovernorates() => _watchGovernorates.all();

  Stream<List<Governorate>> watchAvailableGovernorates() =>
      _watchGovernorates.available();

  Stream<List<PromoBanner>> watchPromoBanners(
    String governorate, {
    String? activityTypeId,
  }) {
    return _bannerRepo.watchByGovernorate(governorate).map((records) {
      final now = DateTime.now();
      PromoBannerDebug.log(
        'Filter Requested Governorate: "$governorate" '
        'activity="$activityTypeId" '
        'read=${records.length} Now: ${now.toIso8601String()}',
      );
      final active = <PromoBannerRecord>[];
      for (final r in records) {
        PromoBannerDebug.dumpLiveStatus(
          record: r,
          requestedGovernorate: governorate,
          now: now,
        );
        if (!r.isLiveAt(now)) continue;
        if (!ActivityScopeUtils.matches(
          activityTypeIds: r.activityTypeIds,
          customerActivityTypeId: activityTypeId ?? '',
        )) {
          continue;
        }
        active.add(r);
      }
      final display = active.map(_toDisplayBanner).toList();
      PromoBannerDebug.log(
        'Filter result Live=${display.length}/${records.length} '
        'ids=${display.map((b) => b.id).join(",")}',
      );
      return display;
    });
  }

  PromoBanner _toDisplayBanner(PromoBannerRecord r) {
    return PromoBanner(
      id: r.id,
      title: r.title,
      subtitle: r.subtitle,
      cta: r.cta,
      imageAsset: r.imageAsset ?? '',
      imageUrl: r.imageUrl,
      imageThumbUrl: r.imageThumbUrl,
      accentColor: r.accentColor,
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
