/// ترميز مستندات Firestore للكاش — `{id, data}`.
abstract final class CacheDocumentCodec {
  static List<dynamic> encodeList(
    Iterable<({String id, Map<String, dynamic> data})> docs,
  ) {
    return docs
        .map((d) => {'id': d.id, 'data': d.data})
        .toList(growable: false);
  }

  static List<({String id, Map<String, dynamic> data})> decodeList(
    List<dynamic> json,
  ) {
    return json
        .map((e) {
          if (e is! Map) return null;
          final id = e['id']?.toString() ?? '';
          final data = e['data'];
          if (id.isEmpty || data is! Map) return null;
          return (
            id: id,
            data: Map<String, dynamic>.from(data),
          );
        })
        .whereType<({String id, Map<String, dynamic> data})>()
        .toList();
  }
}
