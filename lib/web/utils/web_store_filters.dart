import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/models/store.dart';

enum WebStoreSort {
  recommended,
  rating,
  delivery,
  minOrder,
}

enum WebPriceFilter {
  any,
  lowDelivery,
  freeDeliveryEligible,
}

class WebStoreFilterState {
  const WebStoreFilterState({
    this.query = '',
    this.categoryId,
    this.minRating = 0,
    this.maxDeliveryMinutes,
    this.offersOnly = false,
    this.sort = WebStoreSort.recommended,
    this.priceFilter = WebPriceFilter.any,
  });

  final String query;
  final String? categoryId;
  final double minRating;
  final int? maxDeliveryMinutes;
  final bool offersOnly;
  final WebStoreSort sort;
  final WebPriceFilter priceFilter;

  WebStoreFilterState copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
    double? minRating,
    int? maxDeliveryMinutes,
    bool? offersOnly,
    WebStoreSort? sort,
    WebPriceFilter? priceFilter,
  }) {
    return WebStoreFilterState(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minRating: minRating ?? this.minRating,
      maxDeliveryMinutes: maxDeliveryMinutes ?? this.maxDeliveryMinutes,
      offersOnly: offersOnly ?? this.offersOnly,
      sort: sort ?? this.sort,
      priceFilter: priceFilter ?? this.priceFilter,
    );
  }
}

abstract final class WebStoreFilters {
  static List<Store> apply(List<Store> stores, WebStoreFilterState state) {
    var list = StoreCatalogUtils.filterStores(
      stores,
      categoryId: state.categoryId,
    );

    if (state.query.trim().isNotEmpty) {
      final q = state.query.trim().toLowerCase();
      list = list
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.tags.any((t) => t.toLowerCase().contains(q)) ||
                (s.area.toLowerCase().contains(q)),
          )
          .toList();
    }

    if (state.minRating > 0) {
      list = list.where((s) => s.rating >= state.minRating).toList();
    }

    if (state.maxDeliveryMinutes != null) {
      list = list
          .where((s) => s.deliveryMinutes <= state.maxDeliveryMinutes!)
          .toList();
    }

    if (state.offersOnly) {
      list = list
          .where(
            (s) => s.discountLabel != null && s.discountLabel!.isNotEmpty,
          )
          .toList();
    }

    switch (state.priceFilter) {
      case WebPriceFilter.lowDelivery:
        list = list.where((s) => s.deliveryFee <= 15).toList();
      case WebPriceFilter.freeDeliveryEligible:
        list = list.where((s) => s.freeDeliveryThreshold > 0).toList();
      case WebPriceFilter.any:
        break;
    }

    list = list.where((s) => s.isOpen).toList();

    switch (state.sort) {
      case WebStoreSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case WebStoreSort.delivery:
        list.sort((a, b) => a.deliveryMinutes.compareTo(b.deliveryMinutes));
      case WebStoreSort.minOrder:
        list.sort((a, b) => a.minOrderAmount.compareTo(b.minOrderAmount));
      case WebStoreSort.recommended:
        list.sort((a, b) {
          final sa = a.rating * 2 + (a.isFeatured ? 1 : 0);
          final sb = b.rating * 2 + (b.isFeatured ? 1 : 0);
          return sb.compareTo(sa);
        });
    }

    return list;
  }
}
