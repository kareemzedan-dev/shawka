import 'dart:async';

import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/utils/catalog_image_cache.dart';
import 'package:matlobgo/core/utils/catalog_image_urls.dart';
import 'package:matlobgo/core/utils/startup_timing.dart';
import 'package:matlobgo/models/promo_banner_record.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/repositories/promo_banner_repository.dart';

/// يجلب بيانات الرئيسية + ينزّل الصور قبل فتح الشاشة.
class CatalogWarmupService {
  CatalogWarmupService._();

  static final CatalogWarmupService instance = CatalogWarmupService._();

  final _bannerRepo = PromoBannerRepository();
  final _catalog = ServiceLocator.watchCatalog;

  Future<void>? _inflight;
  String? _lastGovernorate;

  Future<void> warmForGovernorate(String governorateName) {
    if (_inflight != null && _lastGovernorate == governorateName) {
      return _inflight!;
    }
    _lastGovernorate = governorateName;
    _inflight = _run(governorateName);
    return _inflight!;
  }

  Future<void> warmDefault() =>
      warmForGovernorate(EgyptGovernorates.defaultGovernorate.name);

  Future<void> _run(String governorateName) async {
    try {
      final urls = await _fetchListImageUrls(governorateName).timeout(
        const Duration(seconds: 4),
        onTimeout: () => const [],
      );
      StartupTiming.mark('catalog_warmup_$governorateName');
      if (urls.isEmpty) return;
      final limited = CatalogImageCache.filterPrefetchable(urls.take(5)).toList();
      if (limited.isEmpty) return;
      unawaited(
        CatalogImageCache.prefetch(limited).timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        ),
      );
    } catch (_) {
      // لا نمنع فتح التطبيق
    }
  }

  Future<List<String>> _fetchListImageUrls(String governorateName) async {
    var banners = <PromoBannerRecord>[];
    var categories = <StoreCategoryDef>[];
    var stores = <Store>[];

    await Future.wait<void>([
      _bannerRepo.watchByGovernorate(governorateName).first.then((v) {
        banners = v;
      }),
      _catalog.categories(governorateName).first.then((v) {
        categories = v;
      }),
      _catalog
          .stores(governorate: governorateName)
          .first
          .then((v) {
        stores = v;
      }),
    ]).timeout(const Duration(seconds: 5), onTimeout: () => []);

    final urls = <String>[];

    for (final banner in banners.where((b) => b.isActive)) {
      _append(urls, banner.imageThumbUrl, banner.imageUrl);
    }
    for (final category in categories) {
      _append(urls, category.imageThumbUrl, category.imageUrl);
    }
    for (final store in stores.take(5)) {
      _append(urls, store.displayHeroThumbUrl, store.displayHeroImageUrl);
    }

    return urls;
  }

  void _append(List<String> urls, String? thumb, String? full) {
    final candidates = catalogImageCandidateUrls(
      thumbnailUrl: thumb,
      imageUrl: full,
    );
    for (final url in candidates.take(4)) {
      urls.add(url);
    }
  }

  static List<String> urlsFromHomeContent({
    required List<PromoBanner> banners,
    required List<StoreCategoryEntry> categories,
    required List<Store> stores,
  }) {
    final urls = <String>[];
    for (final banner in banners) {
      if (!banner.hasNetworkImage) continue;
      for (final url in catalogImageCandidateUrls(
        thumbnailUrl: banner.imageThumbUrl,
        imageUrl: banner.imageUrl,
      ).take(4)) {
        urls.add(url);
      }
    }
    for (final entry in categories) {
      for (final url in catalogImageCandidateUrls(
        thumbnailUrl: entry.definition.imageThumbUrl,
        imageUrl: entry.definition.imageUrl,
      ).take(4)) {
        urls.add(url);
      }
    }
    for (final store in stores.take(5)) {
      for (final url in catalogImageCandidateUrls(
        thumbnailUrl: store.displayHeroThumbUrl,
        imageUrl: store.displayHeroImageUrl,
      ).take(4)) {
        urls.add(url);
      }
    }
    return urls;
  }
}
