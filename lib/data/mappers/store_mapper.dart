import 'package:matlobgo/data/mappers/cache_document_codec.dart';
import 'package:matlobgo/models/store.dart';

abstract final class StoreMapper {
  static List<Store> fromCacheJson(List<dynamic> json) {
    return CacheDocumentCodec.decodeList(json)
        .map((e) => Store.fromMap(id: e.id, data: e.data))
        .toList();
  }

  static List<dynamic> toCacheJson(List<Store> stores) {
    return CacheDocumentCodec.encodeList(
      stores.map((s) => (id: s.id, data: _storeData(s))),
    );
  }

  static Map<String, dynamic> _storeData(Store s) {
    return s.toFirestore()
      ..remove('updatedAt')
      ..remove('createdAt');
  }
}
