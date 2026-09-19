/// Client YAML migration contract.
abstract class ClientMigration {
  int get fromVersion;
  int get toVersion;
  String get id;

  /// Transforms a parsed YAML root map in-place (returns same/new root).
  Map<dynamic, dynamic> migrate(Map<dynamic, dynamic> root);
}
