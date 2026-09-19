import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/debug/cart_preview.dart';

/// Profile harness لشاشة السلة:
/// `flutter run --profile -d <device> -t lib/debug/cart_profile_app.dart`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CartProfileApp());
}

class CartProfileApp extends StatefulWidget {
  const CartProfileApp({super.key});

  @override
  State<CartProfileApp> createState() => _CartProfileAppState();
}

class _CartProfileAppState extends State<CartProfileApp>
    with SingleTickerProviderStateMixin {
  static const warmupSeconds = 2;
  static const idleSeconds = 5;
  static const interactionSeconds = 4;

  final _idleBuild = <double>[];
  final _idleRaster = <double>[];
  final _idleTotal = <double>[];
  final _interactBuild = <double>[];
  final _interactRaster = <double>[];
  final _interactTotal = <double>[];

  late final AnimationController _pulse;
  var _phase = _ProfilePhase.warmup;
  var _qty = 2;
  var _rebuildTicks = 0;
  var _done = false;
  Timer? _interactionTicker;

  @override
  void initState() {
    super.initState();
    // نبض مستمر لضمان إنتاج frames أثناء idle (بدون إعادة بناء شجرة السلة).
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addTimingsCallback(_onTimings);
    Timer(const Duration(seconds: warmupSeconds), () {
      if (!mounted || _done) return;
      setState(() => _phase = _ProfilePhase.idle);
      Timer(const Duration(seconds: idleSeconds), _startInteraction);
    });
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_done || _phase == _ProfilePhase.warmup) return;
    final build = _phase == _ProfilePhase.idle ? _idleBuild : _interactBuild;
    final raster =
        _phase == _ProfilePhase.idle ? _idleRaster : _interactRaster;
    final total = _phase == _ProfilePhase.idle ? _idleTotal : _interactTotal;
    for (final t in timings) {
      build.add(t.buildDuration.inMicroseconds / 1000.0);
      raster.add(t.rasterDuration.inMicroseconds / 1000.0);
      total.add(t.totalSpan.inMicroseconds / 1000.0);
    }
  }

  void _startInteraction() {
    if (!mounted || _done) return;
    setState(() => _phase = _ProfilePhase.interaction);
    _interactionTicker =
        Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _done) return;
      setState(() {
        _qty = _qty == 2 ? 3 : 2;
        _rebuildTicks++;
      });
    });
    Timer(const Duration(seconds: interactionSeconds), _finishAndReport);
  }

  Map<String, dynamic> _stats(List<double> values) {
    if (values.isEmpty) {
      return {
        'count': 0,
        'avgMs': 0,
        'p50Ms': 0,
        'p95Ms': 0,
        'maxMs': 0,
      };
    }
    final sorted = [...values]..sort();
    double pct(double p) {
      final i = (p * (sorted.length - 1)).round().clamp(0, sorted.length - 1);
      return sorted[i];
    }

    final avg = values.reduce((a, b) => a + b) / values.length;
    return {
      'count': values.length,
      'avgMs': double.parse(avg.toStringAsFixed(3)),
      'p50Ms': double.parse(pct(0.50).toStringAsFixed(3)),
      'p95Ms': double.parse(pct(0.95).toStringAsFixed(3)),
      'maxMs': double.parse(sorted.last.toStringAsFixed(3)),
    };
  }

  Map<String, dynamic> _phaseReport({
    required String name,
    required int seconds,
    required List<double> build,
    required List<double> raster,
    required List<double> total,
  }) {
    final totalStats = _stats(total);
    final count = totalStats['count'] as int;
    final fps = count == 0 ? 0.0 : count / seconds;
    return {
      'name': name,
      'sampleSeconds': seconds,
      'frameTime': totalStats,
      'buildTime': _stats(build),
      'rasterTime': _stats(raster),
      'fpsEstimate': double.parse(fps.toStringAsFixed(2)),
      'jankFramesOver16ms': total.where((ms) => ms > 16.67).length,
      'severeJankFramesOver33ms': total.where((ms) => ms > 33.34).length,
    };
  }

  Future<void> _finishAndReport() async {
    if (_done) return;
    _done = true;
    _interactionTicker?.cancel();
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);

    final rssMb = ProcessInfo.currentRss / (1024 * 1024);
    final maxRssMb = ProcessInfo.maxRss / (1024 * 1024);
    final view = WidgetsBinding.instance.platformDispatcher.views.first;

    final report = {
      'screen': 'cart',
      'mode': kReleaseMode
          ? 'release'
          : (kProfileMode ? 'profile' : 'debug'),
      'device': 'android-emulator',
      'devicePixelRatio': view.devicePixelRatio,
      'physicalSize': {
        'width': view.physicalSize.width,
        'height': view.physicalSize.height,
      },
      'warmupSecondsDiscarded': warmupSeconds,
      'phases': [
        _phaseReport(
          name: 'idle',
          seconds: idleSeconds,
          build: _idleBuild,
          raster: _idleRaster,
          total: _idleTotal,
        ),
        _phaseReport(
          name: 'interaction',
          seconds: interactionSeconds,
          build: _interactBuild,
          raster: _interactRaster,
          total: _interactTotal,
        ),
      ],
      'widgetRebuildCountDuringInteraction': _rebuildTicks,
      'garbageCollection': {
        'note':
            'RSS sampled at end; GC pause ms requires DevTools Memory timeline',
        'rssDeltaHintMb': double.parse(
          (maxRssMb - rssMb).abs().toStringAsFixed(2),
        ),
      },
      'memory': {
        'currentRssMb': double.parse(rssMb.toStringAsFixed(2)),
        'maxRssMb': double.parse(maxRssMb.toStringAsFixed(2)),
      },
      'notes': [
        'Profile Mode on Android emulator (x86_64) — slower than physical devices',
        'Idle: cart tree + tiny pulse overlay; warmup frames discarded',
        'Interaction: quantity toggle every 250ms',
        'Primary signal: idle buildTime/rasterTime p95',
      ],
    };

    final json = const JsonEncoder.withIndent('  ').convert(report);
    // ignore: avoid_print
    print('\n===== CART PROFILE REPORT =====\n$json\n===== END =====\n');

    await Future<void>.delayed(const Duration(milliseconds: 500));
    exit(0);
  }

  @override
  void dispose() {
    _interactionTicker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CartPreviewScreen(quantityOverride: _qty),
              Positioned(
                top: 6,
                left: 6,
                child: FadeTransition(
                  opacity: Tween(begin: 0.15, end: 0.35).animate(_pulse),
                  child: const ColoredBox(
                    color: AppColors.navy,
                    child: SizedBox(width: 8, height: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProfilePhase { warmup, idle, interaction }
