#!/usr/bin/env dart
// Creates a new White Label client from clients/templates/default_client.yaml
//
// Usage:
//   dart run tool/create_client.dart --id=acme --app-name=Acme --package=com.acme.app --firebase-project=acme-123
//   dart run tool/create_client.dart --id=acme --app-name=Acme --package=com.acme.app --firebase-project=acme-123 --activate

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('id', help: 'Client id (folder name)', mandatory: true)
    ..addOption('app-name', help: 'Display app name', mandatory: true)
    ..addOption(
      'package',
      help: 'Android applicationId / package',
      mandatory: true,
    )
    ..addOption('bundle-id', help: 'iOS bundle id (defaults to package)')
    ..addOption('company', help: 'Company name (defaults to app-name)')
    ..addOption(
      'firebase-project',
      help: 'Firebase project id',
      mandatory: true,
    )
    ..addOption('region', defaultsTo: 'us-central1')
    ..addFlag(
      'activate',
      defaultsTo: false,
      help: 'Run update_brand after create',
    )
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
  final id = (opts['id'] as String).trim().toLowerCase();
  final appName = (opts['app-name'] as String).trim();
  final packageName = (opts['package'] as String).trim();
  final bundleId = ((opts['bundle-id'] as String?)?.trim().isNotEmpty ?? false)
      ? (opts['bundle-id'] as String).trim()
      : packageName;
  final company = ((opts['company'] as String?)?.trim().isNotEmpty ?? false)
      ? (opts['company'] as String).trim()
      : appName;
  final firebaseProject = (opts['firebase-project'] as String).trim();
  final region = (opts['region'] as String).trim();

  if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(id)) {
    stderr.writeln(
      'Invalid --id "$id" (use lowercase letters, digits, _ or -).',
    );
    exit(64);
  }

  final template = File(
    p.join(root.path, 'clients', 'templates', 'default_client.yaml'),
  );
  if (!template.existsSync()) {
    stderr.writeln('Missing template: ${template.path}');
    exit(1);
  }

  final clientDir = Directory(p.join(root.path, 'clients', id));
  if (clientDir.existsSync()) {
    stderr.writeln('Client already exists: ${clientDir.path}');
    exit(1);
  }
  clientDir.createSync(recursive: true);

  var yaml = template.readAsStringSync();
  yaml = yaml
      .replaceAll('{{CLIENT_ID}}', id)
      .replaceAll('{{APP_NAME}}', appName)
      .replaceAll('{{COMPANY_NAME}}', company)
      .replaceAll('{{PACKAGE_NAME}}', packageName)
      .replaceAll('{{BUNDLE_ID}}', bundleId)
      .replaceAll('{{FIREBASE_PROJECT_ID}}', firebaseProject)
      .replaceAll('region: us-central1', 'region: $region');

  File(p.join(clientDir.path, 'client.yaml')).writeAsStringSync(yaml);

  File(p.join(clientDir.path, 'manifest.json')).writeAsStringSync('''
{
  "version": "1.0.0",
  "schemaVersion": 2,
  "firebase": "$firebaseProject",
  "platform": "enterprise",
  "clientId": "$id",
  "generatedBy": "white-label"
}
''');

  // Seed assets from Shawka defaults when available (placeholders).
  final shawka = Directory(p.join(root.path, 'clients', 'shawka'));
  for (final name in ['logo.png', 'splash.png', 'favicon.png']) {
    final src = File(p.join(shawka.path, name));
    final dest = File(p.join(clientDir.path, name));
    if (src.existsSync()) {
      src.copySync(dest.path);
    } else {
      dest.writeAsBytesSync(const []);
    }
  }

  stdout.writeln('Created client: clients/$id');
  stdout.writeln('  Edit clients/$id/client.yaml then run:');
  stdout.writeln('  dart run tool/validate_client.dart --client=$id');
  stdout.writeln('  dart run tool/generate_brand.dart --client=$id');
  stdout.writeln('  dart run tool/update_brand.dart --client=$id');

  if (opts['activate'] == true) {
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'tool/update_brand.dart', '--client=$id'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
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
      stderr.writeln('Could not find project root (pubspec.yaml + clients/).');
      exit(1);
    }
    dir = parent;
  }
}
