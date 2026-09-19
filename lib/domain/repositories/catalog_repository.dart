import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';

/// عقد طبقة Domain — كتالوج التطبيق.
abstract class CatalogRepository {
  Stream<List<StoreCategoryDef>> watchCategories(
    String governorate, {
    String? activityTypeId,
  });

  Stream<List<Store>> watchStores({
    required String governorate,
    String? categoryId,
    String? activityTypeId,
  });

  Stream<List<Product>> watchProducts(
    String storeId, {
    bool activeOnly,
    String? activityTypeId,
    List<String>? storeActivityTypeIds,
  });

  Future<Store?> getStore(String storeId);
}
