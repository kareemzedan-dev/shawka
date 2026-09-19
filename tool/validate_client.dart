#!/usr/bin/env dart
// Validates clients/<id> before build/generate.
// Exit code 1 = Build Failed.
//
// Usage:
//   dart run tool/validate_client.dart --client=shawka

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:matlobgo/config/branding/client_config.dart';
import 'package:path/path.dart' as p;

import 'client_yaml.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('client', defaultsTo: 'shawka')
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
  final errors = <String>[];
  final warnings = <String>[];

  final clientDir = Directory(p.join(root.path, 'clients', clientId));
  if (!clientDir.existsSync()) {
    errors.add('Missing clients/$clientId/');
    _fail(clientId, errors, warnings);
  }

  final yamlFile = File(p.join(clientDir.path, 'client.yaml'));
  if (!yamlFile.existsSync()) {
    errors.add('Missing clients/$clientId/client.yaml');
    _fail(clientId, errors, warnings);
  }

  late ClientConfig config;
  try {
    config = loadClientConfig(root, clientId);
  } catch (e) {
    errors.add('YAML schema: $e');
    _fail(clientId, errors, warnings);
  }

  if (config.id != clientId) {
    errors.add('client.id "${config.id}" does not match folder "$clientId"');
  }
  if (config.schemaVersion != ClientConfig.supportedSchemaVersion) {
    errors.add(
      'schemaVersion=${config.schemaVersion} (need ${ClientConfig.supportedSchemaVersion}). '
      'Run migrate_client.dart',
    );
  }

  _checkPackage(config.packageName, 'package_name', errors);
  _checkPackage(config.bundleId, 'bundle_id', errors);

  if (config.firebaseProjectId.isEmpty ||
      config.firebaseProjectId.contains('placeholder')) {
    warnings.add(
      'firebase.project_id looks like a placeholder: ${config.firebaseProjectId}',
    );
  }
  if (config.firebaseProjectId.isEmpty) {
    errors.add('firebase.project_id is required');
  }
  if (config.firebaseRegion.isEmpty) {
    errors.add('firebase.region is required');
  }

  for (final name in ['logo.png', 'splash.png', 'favicon.png']) {
    final f = File(p.join(clientDir.path, name));
    if (!f.existsSync() || f.lengthSync() == 0) {
      errors.add('Missing or empty asset: clients/$clientId/$name');
    }
  }

  for (final hex in [
    config.primaryHex,
    config.primaryDarkHex,
    config.primaryLightHex,
    config.secondaryHex,
    config.secondaryLightHex,
    config.accentHex,
  ]) {
    try {
      ClientConfig.hexToColorValue(hex);
    } catch (_) {
      errors.add('Invalid color: $hex');
    }
  }

  if (!_looksLikeEmail(config.supportEmail)) {
    errors.add('Invalid support.email: ${config.supportEmail}');
  }
  if (!_looksLikeUrl(config.website)) {
    errors.add(
      'Invalid support.website (need http/https URL): ${config.website}',
    );
  }
  if (config.supportPhone.trim().isEmpty) {
    errors.add('support.phone is required');
  }
  if (config.address.trim().isEmpty) {
    errors.add('support.address is required');
  }

  final manifest = File(p.join(clientDir.path, 'manifest.json'));
  if (!manifest.existsSync()) {
    errors.add('Missing clients/$clientId/manifest.json');
  } else {
    try {
      final json = jsonDecode(manifest.readAsStringSync());
      if (json is! Map) {
        errors.add('manifest.json must be an object');
      } else {
        if (json['firebase'] != config.firebaseProjectId) {
          warnings.add(
            'manifest.firebase (${json['firebase']}) != client.yaml project_id (${config.firebaseProjectId})',
          );
        }
        if (json['clientId'] != null && json['clientId'] != clientId) {
          errors.add('manifest.clientId mismatch');
        }
      }
    } catch (e) {
      errors.add('manifest.json parse error: $e');
    }
  }

  final options = File(p.join(clientDir.path, 'firebase_options.dart'));
  if (!options.existsSync()) {
    warnings.add(
      'No clients/$clientId/firebase_options.dart (run flutterfire + sync_firebase)',
    );
  }

  if (errors.isNotEmpty) {
    _fail(clientId, errors, warnings);
  }

  stdout.writeln(
    '✓ Client "$clientId" validation passed (schema v${config.schemaVersion}).',
  );
  for (final w in warnings) {
    stdout.writeln('  ! $w');
  }
  exit(0);
}

void _fail(String clientId, List<String> errors, List<String> warnings) {
  stderr.writeln('❌ Build Failed — client "$clientId" validation errors:');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  for (final w in warnings) {
    stderr.writeln('  ! $w');
  }
  exit(1);
}

void _checkPackage(String value, String label, List<String> errors) {
  if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(value)) {
    errors.add(
      'Invalid $label "$value" (expected reverse-DNS like com.company.app)',
    );
  }
}

bool _looksLikeEmail(String v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

bool _looksLikeUrl(String v) {
  final u = Uri.tryParse(v.trim());
  return u != null &&
      (u.scheme == 'http' || u.scheme == 'https') &&
      u.host.isNotEmpty;
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
