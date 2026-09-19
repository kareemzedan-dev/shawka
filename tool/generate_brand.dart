#!/usr/bin/env dart
// Generates split branding Dart files from clients/<id>/client.yaml.
// Runs validate_client first — fails the build if invalid.
//
// Usage:
//   dart run tool/generate_brand.dart --client=shawka
//   dart run tool/generate_brand.dart --client=shawka --skip-validate

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'brand_codegen.dart';
import 'client_yaml.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('client', defaultsTo: 'shawka')
    ..addFlag('skip-validate', defaultsTo: false)
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

  if (opts['skip-validate'] != true) {
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'tool/validate_client.dart', '--client=$clientId'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      exit(result.exitCode);
    }
  }

  final config = loadClientConfig(root, clientId);
  writeBrandGeneratedFiles(root, config);
  copyBrandAssets(root, clientId);
  ensurePubspecBrandAsset(root);

  stdout.writeln(
    'Generated brand for "$clientId" (schema v${config.schemaVersion}):',
  );
  stdout.writeln('  lib/config/branding/generated/colors.g.dart');
  stdout.writeln('  lib/config/branding/generated/strings.g.dart');
  stdout.writeln('  lib/config/branding/generated/assets.g.dart');
  stdout.writeln('  lib/config/branding/generated/branding.g.dart');
  stdout.writeln('  lib/config/branding/generated/branding_values.g.dart');
  stdout.writeln('  assets/branding/current/');
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
