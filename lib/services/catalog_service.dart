import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/domain/usecases/watch_catalog_use_case.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';

/// واجهة التطبيق للكتالوج — تفوّض لـ Use Cases (Clean Architecture).
class CatalogService {
  CatalogService({WatchCatalogUseCase? watchCatalog})
      : _watchCatalog = watchCatalog ?? ServiceLocator.watchCatalog;

  final WatchCatalogUseCase _watchCatalog;

  Stream<List<StoreCategoryDef>> watchCategories(
    String governorate, {
    String? activityTypeId,
  }) =>
      _watchCatalog.categories(
        governorate,
        activityTypeId: activityTypeId,
      );

  Stream<List<Store>> watchStores({
    required String governorate,
    String? categoryId,
    String? activityTypeId,
  }) =>
      _watchCatalog.stores(
        governorate: governorate,
        categoryId: categoryId,
        activityTypeId: activityTypeId,
      );

  Stream<List<Product>> watchProducts(
    Store store, {
    String? activityTypeId,
  }) =>
      _watchCatalog.products(
        store.id,
        activeOnly: true,
        activityTypeId: activityTypeId,
        storeActivityTypeIds: store.activityTypeIds,
      );

  Future<Store?> getStore(String storeId) => _watchCatalog.storeById(storeId);
}
