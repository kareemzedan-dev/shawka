import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/services/catalog_service.dart';

class WebSearchHit {
  const WebSearchHit.store(this.store) : product = null, category = null;
  const WebSearchHit.product(this.store, this.product)
      : category = null;
  const WebSearchHit.category(this.category)
      : store = null,
        product = null;

  final Store? store;
  final Product? product;
  final StoreCategoryDef? category;

  bool get isStore => store != null && product == null;
  bool get isProduct => product != null;
  bool get isCategory => category != null;
}

/// بحث حي — متاجر، منتجات، تصنيفات.
class WebSearchService {
  WebSearchService({CatalogService? catalog})
      : _catalog = catalog ?? CatalogService();

  final CatalogService _catalog;

  List<StoreCategoryDef> filterCategories(
    List<StoreCategoryDef> defs,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return defs;
    return defs
        .where((d) => d.name.toLowerCase().contains(q))
        .toList();
  }

  List<Store> filterStores(List<Store> stores, String query) {
    final q = query.trim().toLowerCase();
    var list = stores.where((s) => s.isOpen).toList();
    if (q.isEmpty) return list;

    return list.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q)) ||
          s.area.toLowerCase().contains(q) ||
          s.categoryLabel.contains(q);
    }).toList();
  }

  Future<List<WebSearchHit>> search({
    required String governorate,
    required String query,
    required List<Store> stores,
    required List<StoreCategoryDef> categories,
    int productStoreLimit = 12,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      final top = stores.where((s) => s.isOpen).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      return top.take(6).map(WebSearchHit.store).toList();
    }

    final hits = <WebSearchHit>[];

    for (final cat in filterCategories(categories, q).take(4)) {
      hits.add(WebSearchHit.category(cat));
    }

    final matchedStores = filterStores(stores, q);
    for (final store in matchedStores.take(8)) {
      hits.add(WebSearchHit.store(store));
    }

    final productStores = matchedStores.isNotEmpty
        ? matchedStores
        : stores.where((s) => s.isOpen).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    final qLower = q.toLowerCase();
    for (final store in productStores.take(productStoreLimit)) {
      final products = await _catalog.watchProducts(store).first;
      for (final product in products) {
        if (!product.isInStock) continue;
        if (product.name.toLowerCase().contains(qLower) ||
            (product.description?.toLowerCase().contains(qLower) ?? false)) {
          hits.add(WebSearchHit.product(store, product));
          if (hits.length >= 20) return hits;
        }
      }
    }

    return hits;
  }

  List<String> suggestions({
    required List<Store> stores,
    required List<StoreCategoryDef> categories,
  }) {
    final names = <String>[
      ...categories.map((c) => c.name),
      ...stores.where((s) => s.isOpen).map((s) => s.name),
    ];
    return names.take(8).toList();
  }
}
