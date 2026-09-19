import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/order_line_item.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_segmented_tabs.dart';

/// Profile مركّز لشاشة الطلبات فقط:
/// `flutter run --profile -d <device> -t lib/debug/orders_profile_app.dart`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrdersProfileApp());
}

Order _sampleOrder({
  required String id,
  required OrderStatus status,
  int etaMinutes = 15,
}) {
  return Order(
    id: id,
    storeName: 'ابو علي',
    category: 'supplier',
    itemsSummary: 'ساندوتش فول',
    itemCount: 2,
    total: 65,
    authoritativeGrandTotal: 75,
    status: status,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    etaMinutes: etaMinutes,
    storeRating: 4.8,
    storeVerified: true,
    lineItems: const [
      OrderLineItem(
        productId: 'p1',
        productName: 'ساندوتش فول',
        quantity: 2,
        unitPrice: 25,
      ),
    ],
  );
}

class OrdersProfileApp extends StatefulWidget {
  const OrdersProfileApp({super.key});

  @override
  State<OrdersProfileApp> createState() => _OrdersProfileAppState();
}

class _OrdersProfileAppState extends State<OrdersProfileApp> {
  static const warmupSeconds = 1;
  static const openSampleSeconds = 3;
  static const tabSwitchSeconds = 3;

  final _openBuild = <double>[];
  final _switchBuild = <double>[];
  var _phase = _Phase.warmup;
  var _selectedTab = 0;
  var _tabSwitches = 0;
  var _done = false;
  Timer? _switchTicker;
  final _openedAt = Stopwatch()..start();
  int? _firstFrameMs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
    Timer(const Duration(seconds: warmupSeconds), () {
      if (!mounted || _done) return;
      setState(() => _phase = _Phase.open);
      Timer(const Duration(seconds: openSampleSeconds), _startTabSwitch);
    });
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_done || _phase == _Phase.warmup) return;
    _firstFrameMs ??= _openedAt.elapsedMilliseconds;
    final bucket = _phase == _Phase.open ? _openBuild : _switchBuild;
    for (final t in timings) {
      bucket.add(t.buildDuration.inMicroseconds / 1000.0);
    }
  }

  void _startTabSwitch() {
    if (!mounted || _done) return;
    setState(() => _phase = _Phase.tabSwitch);
    _switchTicker = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || _done) return;
      setState(() {
        _selectedTab = _selectedTab >= 2 ? 0 : _selectedTab + 1;
        _tabSwitches++;
      });
    });
    Timer(const Duration(seconds: tabSwitchSeconds), _finish);
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
    _switchTicker?.cancel();
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);

    final report = {
      'screen': 'orders',
      'mode': kProfileMode ? 'profile' : (kReleaseMode ? 'release' : 'debug'),
      'focus': [
        'open latency (first frame after warmup)',
        'build cost while idle on orders list',
        'rebuilds while switching segmented tabs',
      ],
      'open': {
        'firstFrameAfterLaunchMs': _firstFrameMs,
        'buildTime': _stats(_openBuild),
      },
      'tabSwitch': {
        'switchCount': _tabSwitches,
        'buildTime': _stats(_switchBuild),
      },
      'notes': [
        'Realtime Firestore order stream requires live backend',
        'UI cost only; controller listens to OrderService (single notifier)',
      ],
    };

    final json = const JsonEncoder.withIndent('  ').convert(report);
    // ignore: avoid_print
    print('\n===== ORDERS PROFILE REPORT =====\n$json\n===== END =====\n');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    exit(0);
  }

  @override
  void dispose() {
    _switchTicker?.cancel();
    super.dispose();
  }

  List<Order> _ordersForTab() => switch (_selectedTab) {
        1 => [_sampleOrder(id: 'ord_done', status: OrderStatus.delivered)],
        2 => [_sampleOrder(id: 'ord_cancel', status: OrderStatus.cancelled)],
        _ => [
            _sampleOrder(id: 'ord_prep', status: OrderStatus.preparing),
            _sampleOrder(
              id: 'ord_way',
              status: OrderStatus.onTheWay,
              etaMinutes: 12,
            ),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final orders = _ordersForTab();
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
          body: SafeArea(
            child: Column(
              children: [
                OrdersSegmentedTabs(
                  selectedIndex: _selectedTab,
                  activeCount: 2,
                  completedCount: 1,
                  cancelledCount: 1,
                  onSelect: (i) => setState(() => _selectedTab = i),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => OrderCard(
                      order: orders[index],
                      expanded: false,
                      onToggleExpand: () {},
                      onTrack: () {},
                      onReorder: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Phase { warmup, open, tabSwitch }
