import 'package:matlobgo/data/mappers/cache_document_codec.dart';
import 'package:matlobgo/models/product.dart';

abstract final class ProductMapper {
  static List<Product> fromCacheJson(List<dynamic> json, String storeId) {
    return CacheDocumentCodec.decodeList(json)
        .map(
          (e) => Product.fromMap(
            storeId: storeId,
            id: e.id,
            data: e.data,
          ),
        )
        .toList();
  }

  static List<dynamic> toCacheJson(List<Product> products) {
    return CacheDocumentCodec.encodeList(
      products.map(
        (p) => (
          id: p.id,
          data: p.toFirestore()..remove('updatedAt'),
        ),
      ),
    );
  }
}
