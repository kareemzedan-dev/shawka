import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/domain/repositories/catalog_repository.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/repositories/store_category_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/services/service_area_service.dart';

/// تنفيذ Domain — يفوّض للمستودعات مع كاش Firestore.
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    StoreRepository? stores,
    ProductRepository? products,
    StoreCategoryRepository? categories,
  })  : _stores = stores ?? StoreRepository(),
        _products = products ?? ProductRepository(),
        _categories = categories ?? StoreCategoryRepository();

  final StoreRepository _stores;
  final ProductRepository _products;
  final StoreCategoryRepository _categories;

  @override
  Stream<List<StoreCategoryDef>> watchCategories(
    String governorate, {
    String? activityTypeId,
  }) =>
      _categories.watchActiveByGovernorate(governorate).map(
            (list) => StoreCatalogUtils.filterCategories(
              list,
              activityTypeId: activityTypeId,
            ),
          );

  @override
  Stream<List<Store>> watchStores({
    required String governorate,
    String? categoryId,
    String? activityTypeId,
  }) =>
      _stores
          .watchActiveStores(
            governorate: governorate,
            categoryId: categoryId,
          )
          .map(
            (list) => StoreCatalogUtils.filterStores(
              list,
              activityTypeId: activityTypeId,
              zoneId: ServiceAreaService.instance.matchedZone?.id,
            ),
          );

  @override
  Stream<List<Product>> watchProducts(
    String storeId, {
    bool activeOnly = true,
    String? activityTypeId,
    List<String>? storeActivityTypeIds,
  }) =>
      _products.watchProducts(storeId, activeOnly: activeOnly).map(
            (list) => list
                .where(
                  (p) => ActivityScopeUtils.productMatches(
                    productActivityTypeIds: p.activityTypeIds,
                    storeActivityTypeIds: storeActivityTypeIds ?? const [],
                    customerActivityTypeId: activityTypeId ?? '',
                  ),
                )
                .toList(growable: false),
          );

  @override
  Future<Store?> getStore(String storeId) => _stores.getStore(storeId);
}
