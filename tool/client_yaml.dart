import 'dart:io';

import 'package:matlobgo/config/branding/client_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

ClientConfig loadClientConfig(Directory root, String clientId) {
  final file = File(p.join(root.path, 'clients', clientId, 'client.yaml'));
  if (!file.existsSync()) {
    throw FileSystemException('client.yaml not found', file.path);
  }
  final doc = loadYaml(file.readAsStringSync());
  if (doc is! Map) {
    throw FormatException('client.yaml root must be a map: ${file.path}');
  }
  return ClientConfig.fromMap(Map<dynamic, dynamic>.from(doc));
}
