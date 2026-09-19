import 'package:matlobgo/domain/repositories/catalog_repository.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';

/// Use case — مراقبة كتالوج المحافظة (مع كاش عبر Repository).
class WatchCatalogUseCase {
  WatchCatalogUseCase(this._repository);

  final CatalogRepository _repository;

  Stream<List<StoreCategoryDef>> categories(
    String governorate, {
    String? activityTypeId,
  }) =>
      _repository.watchCategories(
        governorate,
        activityTypeId: activityTypeId,
      );

  Stream<List<Store>> stores({
    required String governorate,
    String? categoryId,
    String? activityTypeId,
  }) =>
      _repository.watchStores(
        governorate: governorate,
        categoryId: categoryId,
        activityTypeId: activityTypeId,
      );

  Stream<List<Product>> products(
    String storeId, {
    bool activeOnly = true,
    String? activityTypeId,
    List<String>? storeActivityTypeIds,
  }) =>
      _repository.watchProducts(
        storeId,
        activeOnly: activeOnly,
        activityTypeId: activityTypeId,
        storeActivityTypeIds: storeActivityTypeIds,
      );

  Future<Store?> storeById(String storeId) => _repository.getStore(storeId);
}
