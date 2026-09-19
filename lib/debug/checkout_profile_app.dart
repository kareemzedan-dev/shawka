import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/debug/checkout_preview.dart';

/// Profile مركّز لـ Checkout فقط:
/// `flutter run --profile -d <device> -t lib/debug/checkout_profile_app.dart`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CheckoutProfileApp());
}

class CheckoutProfileApp extends StatefulWidget {
  const CheckoutProfileApp({super.key});

  @override
  State<CheckoutProfileApp> createState() => _CheckoutProfileAppState();
}

class _CheckoutProfileAppState extends State<CheckoutProfileApp> {
  static const warmupSeconds = 1;
  static const openSampleSeconds = 3;
  static const paymentToggleSeconds = 3;

  final _openBuild = <double>[];
  final _toggleBuild = <double>[];
  var _phase = _Phase.warmup;
  var _selectedCash = true;
  var _paymentRebuilds = 0;
  var _done = false;
  Timer? _toggleTicker;
  final _openedAt = Stopwatch()..start();
  int? _firstFrameMs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
    Timer(const Duration(seconds: warmupSeconds), () {
      if (!mounted || _done) return;
      setState(() => _phase = _Phase.open);
      Timer(const Duration(seconds: openSampleSeconds), _startPaymentToggle);
    });
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_done || _phase == _Phase.warmup) return;
    _firstFrameMs ??= _openedAt.elapsedMilliseconds;
    final bucket = _phase == _Phase.open ? _openBuild : _toggleBuild;
    for (final t in timings) {
      bucket.add(t.buildDuration.inMicroseconds / 1000.0);
    }
  }

  void _startPaymentToggle() {
    if (!mounted || _done) return;
    setState(() => _phase = _Phase.paymentToggle);
    _toggleTicker = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || _done) return;
      setState(() {
        _selectedCash = !_selectedCash;
        _paymentRebuilds++;
      });
    });
    Timer(const Duration(seconds: paymentToggleSeconds), _finish);
  }

  Map<String, dynamic> _stats(List<double> values) {
    if (values.isEmpty) {
      return {'count': 0, 'avgMs': 0, 'p95Ms': 0, 'maxMs': 0};
    }
    final sorted = [...values]..sort();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final p95 = sorted[((0.95 * (sorted.length - 1)).round())
        .clamp(0, sorted.length - 1)];
    return {
      'count': values.length,
      'avgMs': double.parse(avg.toStringAsFixed(3)),
      'p95Ms': double.parse(p95.toStringAsFixed(3)),
      'maxMs': double.parse(sorted.last.toStringAsFixed(3)),
    };
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    _toggleTicker?.cancel();
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);

    final report = {
      'screen': 'checkout',
      'mode': kProfileMode ? 'profile' : (kReleaseMode ? 'release' : 'debug'),
      'focus': [
        'open latency (first frame after warmup)',
        'build cost while idle on checkout',
        'rebuilds while toggling payment method',
      ],
      'open': {
        'firstFrameAfterLaunchMs': _firstFrameMs,
        'buildTime': _stats(_openBuild),
      },
      'paymentMethodToggle': {
        'rebuildTicks': _paymentRebuilds,
        'buildTime': _stats(_toggleBuild),
      },
      'notes': [
        'Preview/place CF latency requires live backend — not included here',
        'UI cost only; reuse Cart patterns for listeners/debounce',
      ],
    };

    final json = const JsonEncoder.withIndent('  ').convert(report);
    // ignore: avoid_print
    print('\n===== CHECKOUT PROFILE REPORT =====\n$json\n===== END =====\n');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    exit(0);
  }

  @override
  void dispose() {
    _toggleTicker?.cancel();
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
              const CheckoutPreviewScreen(),
              Positioned(
                top: 8,
                left: 8,
                child: Text(
                  'PAY ${_selectedCash ? 'cash' : 'card'} · $_paymentRebuilds',
                  style: const TextStyle(fontSize: 10, color: AppColors.navy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Phase { warmup, open, paymentToggle }
