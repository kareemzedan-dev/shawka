#!/usr/bin/env dart
// Copies the official logo into client + branding slots and builds
// favicon / launcher icon derivatives. Visual assets only.
//
// Usage:
//   dart run tool/prepare_brand_assets.dart --source=assets/images/logo.png

import 'dart:io';

import 'package:args/args.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'source',
      defaultsTo: 'assets/images/logo.png',
      help: 'Official square logo path',
    )
    ..addOption('client', defaultsTo: 'shawka')
    ..addFlag('help', abbr: 'h', negatable: false);

  final opts = parser.parse(args);
  if (opts['help'] == true) {
    stdout.writeln(parser.usage);
    exit(0);
  }

  final root = Directory.current.path;
  final sourcePath = p.join(root, opts['source'] as String);
  final clientId = opts['client'] as String;
  final sourceFile = File(sourcePath);
  if (!await sourceFile.exists()) {
    stderr.writeln('Source logo not found: $sourcePath');
    exit(1);
  }

  final bytes = await sourceFile.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Could not decode logo image.');
    exit(1);
  }

  final clientDir = p.join(root, 'clients', clientId);
  final brandingDir = p.join(root, 'assets', 'branding', 'current');
  final imagesDir = p.join(root, 'assets', 'images');
  await Directory(clientDir).create(recursive: true);
  await Directory(brandingDir).create(recursive: true);
  await Directory(imagesDir).create(recursive: true);

  Future<void> writePng(String path, img.Image image) async {
    await File(path).writeAsBytes(img.encodePng(image));
    stdout.writeln('Wrote $path (${image.width}x${image.height})');
  }

  // Full logo → client + active branding + splash (black canvas matches logo).
  for (final path in [
    p.join(clientDir, 'logo.png'),
    p.join(clientDir, 'splash.png'),
    p.join(brandingDir, 'logo.png'),
    p.join(brandingDir, 'splash.png'),
  ]) {
    await File(path).writeAsBytes(bytes);
    stdout.writeln('Copied logo → $path');
  }

  final favicon = img.copyResize(
    decoded,
    width: 64,
    height: 64,
    interpolation: img.Interpolation.average,
  );
  await writePng(p.join(clientDir, 'favicon.png'), favicon);
  await writePng(p.join(brandingDir, 'favicon.png'), favicon);

  final icon = img.copyResize(
    decoded,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.average,
  );
  await writePng(p.join(imagesDir, 'icon.png'), icon);

  stdout.writeln('Brand assets prepared for client "$clientId".');
}
