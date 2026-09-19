#!/usr/bin/env dart
// Applies clients/<id>/client.yaml → generated brand + native/web metadata.
// Prefer: dart run tool/generate_brand.dart (codegen) then this for native patches,
// or run this alone (calls generate_brand).
//
// Usage:
//   dart run tool/update_brand.dart --client=shawka

import 'dart:io';

import 'package:args/args.dart';
import 'package:matlobgo/config/branding/client_config.dart';
import 'package:path/path.dart' as p;

import 'client_yaml.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'client',
      defaultsTo: 'shawka',
      help: 'Client id under clients/',
    )
    ..addFlag(
      'skip-native',
      defaultsTo: false,
      help: 'Skip Android/iOS/Web patches',
    )
    ..addFlag(
      'skip-validate',
      defaultsTo: false,
      help: 'Skip validate_client before generate',
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
  final clientId = (opts['client'] as String).trim();

  final genArgs = <String>[
    'run',
    'tool/generate_brand.dart',
    '--client=$clientId',
  ];
  if (opts['skip-validate'] == true) {
    genArgs.add('--skip-validate');
  }
  final gen = await Process.run(
    Platform.resolvedExecutable,
    genArgs,
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(gen.stdout);
  stderr.write(gen.stderr);
  if (gen.exitCode != 0) exit(gen.exitCode);

  final config = loadClientConfig(root, clientId);

  if (opts['skip-native'] != true) {
    _patchAndroid(root, config);
    _patchIos(root, config);
    _patchWeb(root, config);
  }

  stdout.writeln(
    'Updated branding for client="$clientId" (schema v${config.schemaVersion}).',
  );
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

void _patchAndroid(Directory root, ClientConfig c) {
  final gradle = File(p.join(root.path, 'android', 'app', 'build.gradle.kts'));
  if (gradle.existsSync()) {
    var t = gradle.readAsStringSync();
    t = t.replaceAllMapped(
      RegExp(r'namespace\s*=\s*"[^"]+"'),
      (_) => 'namespace = "${c.packageName}"',
    );
    t = t.replaceAllMapped(
      RegExp(r'applicationId\s*=\s*"[^"]+"'),
      (_) => 'applicationId = "${c.packageName}"',
    );
    gradle.writeAsStringSync(t);
  }

  final manifest = File(
    p.join(root.path, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  if (manifest.existsSync()) {
    var t = manifest.readAsStringSync();
    t = t.replaceAllMapped(
      RegExp(r'android:label="[^"]*"'),
      (_) => 'android:label="${c.appName}"',
    );
    manifest.writeAsStringSync(t);
  }
}

void _patchIos(Directory root, ClientConfig c) {
  final pbx = File(
    p.join(root.path, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
  );
  if (pbx.existsSync()) {
    var t = pbx.readAsStringSync();
    t = t.replaceAllMapped(RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;'), (m) {
      final line = m.group(0)!;
      if (line.contains('RunnerTests')) {
        return 'PRODUCT_BUNDLE_IDENTIFIER = ${c.bundleId}.RunnerTests;';
      }
      return 'PRODUCT_BUNDLE_IDENTIFIER = ${c.bundleId};';
    });
    pbx.writeAsStringSync(t);
  }

  final plist = File(p.join(root.path, 'ios', 'Runner', 'Info.plist'));
  if (plist.existsSync()) {
    var t = plist.readAsStringSync();
    t = _replacePlistString(t, 'CFBundleDisplayName', c.appName);
    t = _replacePlistString(t, 'CFBundleName', c.appName);
    plist.writeAsStringSync(t);
  }
}

String _replacePlistString(String plist, String key, String value) {
  final pattern = RegExp(
    '<key>$key</key>\\s*<string>[^<]*</string>',
    multiLine: true,
  );
  return plist.replaceFirstMapped(
    pattern,
    (_) => '<key>$key</key>\n\t<string>$value</string>',
  );
}

void _patchWeb(Directory root, ClientConfig c) {
  final index = File(p.join(root.path, 'web', 'index.html'));
  if (index.existsSync()) {
    var t = index.readAsStringSync();
    t = t.replaceAllMapped(
      RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
      (_) => '<meta name="apple-mobile-web-app-title" content="${c.appName}">',
    );
    t = t.replaceAllMapped(
      RegExp(r'<meta property="og:site_name" content="[^"]*">'),
      (_) => '<meta property="og:site_name" content="${c.appName}">',
    );
    t = t.replaceAllMapped(
      RegExp(r'<meta name="theme-color" content="[^"]*">'),
      (_) => '<meta name="theme-color" content="${c.secondaryHex}">',
    );
    t = t.replaceAllMapped(
      RegExp(r'<title>[^<]*</title>'),
      (_) => '<title>${c.appName} — اطلب طعام وماركت | توصيل سريع</title>',
    );
    t = t.replaceAllMapped(
      RegExp(r'(<meta property="og:title" content=")[^"]*(">)'),
      (m) => '${m[1]}${c.appName} — اطلب من بيتك${m[2]}',
    );
    t = t.replaceAllMapped(
      RegExp(r'(<meta name="twitter:title" content=")[^"]*(">)'),
      (m) => '${m[1]}${c.appName} — اطلب من بيتك${m[2]}',
    );
    index.writeAsStringSync(t);
  }

  final manifest = File(p.join(root.path, 'web', 'manifest.json'));
  if (manifest.existsSync()) {
    var t = manifest.readAsStringSync();
    t = t.replaceAllMapped(
      RegExp(r'"short_name":\s*"[^"]*"'),
      (_) => '"short_name": "${c.appName}"',
    );
    t = t.replaceAllMapped(
      RegExp(r'"name":\s*"[^"]*"'),
      (_) => '"name": "${c.appName} — اطلب من بيتك"',
    );
    t = t.replaceAllMapped(
      RegExp(r'"theme_color":\s*"[^"]*"'),
      (_) => '"theme_color": "${c.secondaryHex}"',
    );
    t = t.replaceAllMapped(
      RegExp(r'"id":\s*"com\.[^"]*"'),
      (_) => '"id": "${c.packageName}"',
    );
    manifest.writeAsStringSync(t);
  }

  final fav = File(
    p.join(root.path, 'assets', 'branding', 'current', 'favicon.png'),
  );
  if (fav.existsSync()) {
    fav.copySync(p.join(root.path, 'web', 'favicon.png'));
  }
}
