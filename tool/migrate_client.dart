#!/usr/bin/env dart
// Migrates clients/<id>/client.yaml across schema versions.
//
// Usage:
//   dart run tool/migrate_client.dart --client=shawka
//   dart run tool/migrate_client.dart --client=shawka --dry-run

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'migrations/migration.dart';
import 'migrations/v1_to_v2.dart';

final List<ClientMigration> _migrations = [MigrateV1ToV2()];

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('client', defaultsTo: 'shawka')
    ..addFlag('dry-run', defaultsTo: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  late ArgResults opts;
  try {
    opts = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }
  if (opts['help'] == true) {
    stdout.writeln(parser.usage);
    exit(0);
  }

  final root = _findProjectRoot();
  final clientId = (opts['client'] as String).trim();
  final file = File(p.join(root.path, 'clients', clientId, 'client.yaml'));
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}');
    exit(1);
  }

  final doc = loadYaml(file.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('client.yaml root must be a map');
    exit(1);
  }

  var rootMap = _deepCopyMap(doc);
  final client = rootMap['client'];
  var version = 0;
  if (client is Map) {
    version = int.tryParse('${client['schemaVersion']}') ?? 0;
  }

  final target = _migrations
      .map((m) => m.toVersion)
      .fold<int>(0, (a, b) => a > b ? a : b);
  if (version >= target) {
    stdout.writeln(
      'Client "$clientId" already at schemaVersion=$version (target=$target).',
    );
    exit(0);
  }

  final applied = <String>[];
  for (final m in _migrations) {
    if (version == m.fromVersion) {
      rootMap = m.migrate(rootMap);
      version = m.toVersion;
      applied.add(m.id);
    }
  }

  if (version < target) {
    stderr.writeln(
      'Could not migrate "$clientId" from schemaVersion=$version to $target. '
      'Missing migration path.',
    );
    exit(1);
  }

  final yamlOut = _toYaml(rootMap);
  if (opts['dry-run'] == true) {
    stdout.writeln('Dry-run migrations: ${applied.join(', ')}');
    stdout.writeln(yamlOut);
    exit(0);
  }

  // Backup then write.
  file.copySync('${file.path}.bak');
  file.writeAsStringSync(yamlOut);

  // Refresh manifest schemaVersion if present.
  final manifest = File(
    p.join(root.path, 'clients', clientId, 'manifest.json'),
  );
  if (manifest.existsSync()) {
    var t = manifest.readAsStringSync();
    t = t.replaceAllMapped(
      RegExp(r'"schemaVersion"\s*:\s*\d+'),
      (_) => '"schemaVersion": $version',
    );
    manifest.writeAsStringSync(t);
  }

  stdout.writeln(
    'Migrated clients/$clientId (${applied.join(' → ')}) → schemaVersion=$version',
  );
  stdout.writeln('Backup: clients/$clientId/client.yaml.bak');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync() &&
        Directory(p.join(dir.path, 'clients')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('Could not find project root.');
      exit(1);
    }
    dir = parent;
  }
}

Map<dynamic, dynamic> _deepCopyMap(Map input) {
  final out = <dynamic, dynamic>{};
  input.forEach((k, v) {
    if (v is Map) {
      out[k] = _deepCopyMap(v);
    } else if (v is List) {
      out[k] = v.map((e) => e is Map ? _deepCopyMap(e) : e).toList();
    } else {
      out[k] = v;
    }
  });
  return out;
}

String _toYaml(Map<dynamic, dynamic> root) {
  final buf = StringBuffer();
  void writeNode(dynamic value, int indent) {
    final pad = '  ' * indent;
    if (value is Map) {
      for (final entry in value.entries) {
        final k = entry.key;
        final v = entry.value;
        if (v is Map) {
          buf.writeln('$pad$k:');
          writeNode(v, indent + 1);
        } else if (v is List) {
          buf.writeln('$pad$k:');
          for (final item in v) {
            buf.writeln('$pad  - ${_scalar(item)}');
          }
        } else {
          buf.writeln('$pad$k: ${_scalar(v)}');
        }
      }
    }
  }

  writeNode(root, 0);
  return buf.toString();
}

String _scalar(dynamic v) {
  if (v is bool || v is num) return '$v';
  final s = '$v';
  if (s.contains(':') ||
      s.contains('#') ||
      s.contains("'") ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('—') ||
      RegExp(r'[\u0600-\u06FF]').hasMatch(s) ||
      s.contains(' ')) {
    return '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }
  return s;
}
