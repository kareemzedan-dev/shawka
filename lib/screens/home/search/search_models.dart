import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';

/// نتيجة بحث مرتّبة — متجر و/أو منتج مطابق.
class SearchHit {
  const SearchHit.store({
    required this.store,
    required this.score,
    this.matchedVia = SearchMatchVia.storeName,
  })  : product = null,
        category = null;

  const SearchHit.product({
    required this.store,
    required this.product,
    required this.score,
  })  : matchedVia = SearchMatchVia.productName,
        category = null;

  const SearchHit.category({
    required this.category,
    required this.score,
  })  : store = null,
        product = null,
        matchedVia = SearchMatchVia.category;

  final Store? store;
  final Product? product;
  final StoreCategoryDef? category;
  final int score;
  final SearchMatchVia matchedVia;

  bool get isStore => store != null && product == null;
  bool get isProduct => product != null;
  bool get isCategory => category != null;
}

enum SearchMatchVia {
  storeName,
  tags,
  category,
  keyword,
  productName,
}

enum SearchUiPhase {
  initial,
  loading,
  success,
  empty,
  error,
  offline,
}

/// فلاتر متقدّمة من زر التصفية في الهيرو.
class SearchAdvancedFilters {
  const SearchAdvancedFilters({
    this.openOnly = false,
    this.freeDeliveryOnly = false,
    this.offersOnly = false,
  });

  final bool openOnly;
  final bool freeDeliveryOnly;
  final bool offersOnly;

  bool get isDefault => !openOnly && !freeDeliveryOnly && !offersOnly;

  SearchAdvancedFilters copyWith({
    bool? openOnly,
    bool? freeDeliveryOnly,
    bool? offersOnly,
  }) {
    return SearchAdvancedFilters(
      openOnly: openOnly ?? this.openOnly,
      freeDeliveryOnly: freeDeliveryOnly ?? this.freeDeliveryOnly,
      offersOnly: offersOnly ?? this.offersOnly,
    );
  }
}

/// شريحة شائعة — نص + تمييز عرض ساخن اختياري.
class PopularSearchTerm {
  const PopularSearchTerm({
    required this.label,
    this.hot = false,
  });

  final String label;
  final bool hot;
}
