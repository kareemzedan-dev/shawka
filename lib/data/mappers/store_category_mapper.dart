import 'package:matlobgo/data/mappers/cache_document_codec.dart';
import 'package:matlobgo/models/store_category_def.dart';

abstract final class StoreCategoryMapper {
  static List<StoreCategoryDef> fromCacheJson(List<dynamic> json) {
    return CacheDocumentCodec.decodeList(json)
        .map(
          (e) => StoreCategoryDef.fromMap(id: e.id, data: e.data),
        )
        .toList();
  }

  static List<dynamic> toCacheJson(List<StoreCategoryDef> list) {
    return CacheDocumentCodec.encodeList(
      list.map(
        (c) => (
          id: c.id,
          data: c.toFirestore()..remove('updatedAt'),
        ),
      ),
    );
  }
}
