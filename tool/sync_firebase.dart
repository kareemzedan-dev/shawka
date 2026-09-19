#!/usr/bin/env dart
// Syncs Firebase options + .firebaserc from clients/<id>.
// Does NOT run `flutterfire configure` (interactive).
//
// Usage:
//   dart run tool/sync_firebase.dart --client=shawka

import 'dart:io';

import 'package:args/args.dart';
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
  final config = loadClientConfig(root, clientId);

  final clientOptions = File(
    p.join(root.path, 'clients', clientId, 'firebase_options.dart'),
  );
  final libOptions = File(p.join(root.path, 'lib', 'firebase_options.dart'));

  if (clientOptions.existsSync()) {
    clientOptions.copySync(libOptions.path);
    stdout.writeln('Copied clients/$clientId/firebase_options.dart → lib/');
  } else {
    stdout.writeln(
      'No clients/$clientId/firebase_options.dart — skipped copy.\n'
      'Run `flutterfire configure` for project ${config.firebaseProjectId}, '
      'then copy the result into clients/$clientId/firebase_options.dart.',
    );
  }

  final firebaserc = File(p.join(root.path, '.firebaserc'));
  firebaserc.writeAsStringSync('''
{
  "projects": {
    "default": "${config.firebaseProjectId}"
  },
  "targets": {},
  "etags": {}
}
''');
  stdout.writeln('Updated .firebaserc default → ${config.firebaseProjectId}');
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
