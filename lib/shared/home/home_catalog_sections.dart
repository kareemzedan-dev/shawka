import 'package:matlobgo/models/promotion.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/widgets/home_quick_filters.dart';

/// Store section helpers — same logic as mobile Home tab.
abstract final class HomeCatalogSections {
  static List<Store> featured(List<Store> allInGov) {
    final stores = allInGov.where((s) => s.isFeaturedNow && s.isOpen).toList();
    stores.sort((a, b) {
      final priority = b.featuredPriority.compareTo(a.featuredPriority);
      return priority != 0 ? priority : b.rating.compareTo(a.rating);
    });
    return stores;
  }

  static List<Store> trending(List<Store> allInGov, List<Store> featured) {
    final featuredIds = featured.map((s) => s.id).toSet();
    final candidates =
        allInGov
            .where((s) => s.isOpen && !featuredIds.contains(s.id))
            .where((s) => s.rating >= 4.5)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
    return candidates.take(8).toList();
  }

  /// متاجر لها عرض ظاهر في «عروض البرق» — نص خصم على المتجر أو عرض نشط مربوط بمتجر.
  static List<Store> flashDealStores(
    List<Store> all, {
    List<Promotion> promotions = const [],
  }) {
    final promoByStore = <String, Promotion>{};
    for (final promo in promotions) {
      if (!promo.isValidNow || promo.storeId.isEmpty) continue;
      promoByStore.putIfAbsent(promo.storeId, () => promo);
    }

    final result = <Store>[];
    final seen = <String>{};

    for (final store in all) {
      if (!store.isActive || !store.isOpen || seen.contains(store.id)) {
        continue;
      }
      final hasDiscountLabel =
          store.discountLabel != null && store.discountLabel!.trim().isNotEmpty;
      final hasStorePromo = promoByStore.containsKey(store.id);
      if (!hasDiscountLabel && !hasStorePromo) continue;
      seen.add(store.id);
      result.add(store);
    }

    result.sort((a, b) {
      final scoreA = _flashDealScore(a, promoByStore);
      final scoreB = _flashDealScore(b, promoByStore);
      return scoreB.compareTo(scoreA);
    });

    return result.take(12).toList();
  }

  static int _flashDealScore(Store store, Map<String, Promotion> promoByStore) {
    var score = 0;
    if (promoByStore.containsKey(store.id)) score += 2;
    if (store.discountLabel != null && store.discountLabel!.trim().isNotEmpty) {
      score += 1;
    }
    return score;
  }

  static String? flashDealLabel(
    Store store, {
    List<Promotion> promotions = const [],
  }) {
    final label = store.discountLabel?.trim();
    if (label != null && label.isNotEmpty) return label;

    Promotion? best;
    for (final promo in promotions) {
      if (!promo.isValidNow || promo.storeId != store.id) continue;
      if (best == null || promo.sortOrder < best.sortOrder) {
        best = promo;
      }
    }
    if (best == null) return null;
    return promotionDisplayLabel(best);
  }

  static String promotionDisplayLabel(Promotion promotion) {
    final title = promotion.title.trim();
    if (title.isNotEmpty) return title;
    return switch (promotion.type) {
      PromotionType.percent => 'خصم ${promotion.value.round()}%',
      PromotionType.fixedAmount => 'خصم ${promotion.value.round()} ج.م',
      PromotionType.freeDelivery => 'توصيل مجاني',
    };
  }

  static String categorySectionTitle(
    String? selectedCategoryId,
    List<StoreCategoryEntry> categories,
  ) {
    if (selectedCategoryId == null) return 'كل الموردين';
    for (final c in categories) {
      if (c.definition.id == selectedCategoryId) {
        final name = c.definition.name.trim();
        if (name.isNotEmpty) return name;
        break;
      }
    }
    return 'موردين';
  }

  static String categoryTypeLabel({
    String? selectedCategoryId,
    String? selectedCategoryName,
    List<StoreCategoryDef> definitions = const [],
  }) {
    if (selectedCategoryName != null && selectedCategoryName.trim().isNotEmpty) {
      return selectedCategoryName.trim();
    }
    if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
      for (final d in definitions) {
        if (d.id == selectedCategoryId && d.name.trim().isNotEmpty) {
          return d.name.trim();
        }
      }
    }
    return 'موردين';
  }

  static String emptyStoresTitle({
    required String governorateName,
    String? selectedCategoryId,
    String? selectedCategoryName,
    List<StoreCategoryDef> definitions = const [],
  }) {
    final label = categoryTypeLabel(
      selectedCategoryId: selectedCategoryId,
      selectedCategoryName: selectedCategoryName,
      definitions: definitions,
    );
    return 'لا توجد $label في $governorateName';
  }

  static String emptyStoresSubtitle({
    String? selectedCategoryId,
    String? selectedCategoryName,
    List<StoreCategoryDef> definitions = const [],
  }) {
    final label = categoryTypeLabel(
      selectedCategoryId: selectedCategoryId,
      selectedCategoryName: selectedCategoryName,
      definitions: definitions,
    );
    if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
      return 'لا توجد شركات مضافة في تصنيف «$label» حالياً — جرّب تصنيفاً آخر';
    }
    return 'جرّب محافظة أخرى أو تصنيفاً مختلفاً';
  }

  static List<Store> applyQuickFilter(
    List<Store> stores,
    HomeQuickFilter filter,
  ) {
    return switch (filter) {
      HomeQuickFilter.all => stores,
      HomeQuickFilter.offers =>
        stores
            .where(
              (s) =>
                  s.discountLabel != null && s.discountLabel!.trim().isNotEmpty,
            )
            .toList(),
      HomeQuickFilter.freeDelivery =>
        stores.where((s) => s.deliveryFee == 0).toList(),
    };
  }

  static List<Store> resolveMostOrdered({
    required List<Store> featured,
    required List<Store> trending,
    required List<Store> allStores,
  }) {
    // فضّل المتاجر المفتوحة ضمن النطاق الحالي (تصنيف/محافظة).
    final scopedOpen = allStores.where((s) => s.isActive && s.isOpen).toList()
      ..sort((a, b) {
        final feat = (b.isFeaturedNow ? 1 : 0).compareTo(a.isFeaturedNow ? 1 : 0);
        if (feat != 0) return feat;
        return b.rating.compareTo(a.rating);
      });
    if (scopedOpen.isNotEmpty) return scopedOpen.take(12).toList();

    final fromTrending =
        trending.where((s) => s.isActive && s.isOpen).take(12).toList();
    if (fromTrending.isNotEmpty) return fromTrending;

    final fromFeatured =
        featured.where((s) => s.isActive && s.isOpen).take(12).toList();
    if (fromFeatured.isNotEmpty) return fromFeatured;

    return allStores.where((s) => s.isActive).take(12).toList();
  }
}

/// Dynamic home layout — sections and titles change per selected category.
class MatlobHomeDynamicLayout {
  const MatlobHomeDynamicLayout({
    required this.showContextHeader,
    required this.contextTitle,
    required this.showMostOrdered,
    required this.mostOrderedTitle,
    required this.showOffers,
    required this.offersTitle,
    required this.allStoresTitle,
  });

  final bool showContextHeader;
  final String contextTitle;
  final bool showMostOrdered;
  final String mostOrderedTitle;
  final bool showOffers;
  final String offersTitle;
  final String allStoresTitle;

  static MatlobHomeDynamicLayout resolve({
    String? selectedCategoryName,
    String mostOrderedCms = 'الأكثر طلباً',
  }) {
    if (selectedCategoryName != null && selectedCategoryName.trim().isNotEmpty) {
      final name = selectedCategoryName.trim();
      return MatlobHomeDynamicLayout(
        showContextHeader: true,
        contextTitle: name,
        showMostOrdered: true,
        mostOrderedTitle: mostOrderedCms,
        showOffers: true,
        offersTitle: 'العروض',
        allStoresTitle: name,
      );
    }

    return MatlobHomeDynamicLayout(
      showContextHeader: false,
      contextTitle: '',
      showMostOrdered: true,
      mostOrderedTitle: mostOrderedCms,
      showOffers: false,
      offersTitle: '',
      allStoresTitle: 'كل الموردين',
    );
  }
}
