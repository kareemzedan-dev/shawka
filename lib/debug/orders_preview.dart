import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/order_line_item.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_segmented_tabs.dart';

/// معاينة Firebase-free لبطاقات الطلبات (ملف debug فقط).
///
/// تشغيل: `flutter run -t lib/debug/orders_preview.dart`
void main() {
  runApp(const OrdersPreviewApp());
}

class OrdersPreviewApp extends StatelessWidget {
  const OrdersPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: _OrdersPreviewPage(),
      ),
    );
  }
}

class _OrdersPreviewPage extends StatefulWidget {
  const _OrdersPreviewPage();

  @override
  State<_OrdersPreviewPage> createState() => _OrdersPreviewPageState();
}

class _OrdersPreviewPageState extends State<_OrdersPreviewPage> {
  int _tab = 0;
  bool _expanded = false;

  Order get _active => Order(
        id: 'ord_8VNX35T7',
        storeName: 'ابو علي',
        category: 'supplier',
        itemsSummary: 'ساندوتش فول',
        itemCount: 3,
        total: 65,
        authoritativeGrandTotal: 75,
        status: OrderStatus.preparing,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        etaMinutes: 15,
        storeRating: 4.8,
        storeVerified: true,
        lineItems: const [
          OrderLineItem(
            productId: 'p1',
            productName: 'ساندوتش فول',
            quantity: 2,
            unitPrice: 25,
          ),
          OrderLineItem(
            productId: 'p2',
            productName: 'طحينة',
            quantity: 1,
            unitPrice: 15,
          ),
        ],
      );

  Order get _completed => _active.copyWith(status: OrderStatus.delivered);

  @override
  Widget build(BuildContext context) {
    final order = _tab == 0 ? _active : _completed;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Orders Preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrdersSegmentedTabs(
            selectedIndex: _tab,
            activeCount: 1,
            completedCount: 1,
            cancelledCount: 0,
            onSelect: (i) => setState(() => _tab = i.clamp(0, 1)),
          ),
          const SizedBox(height: 16),
          OrderCard(
            order: order,
            expanded: _expanded,
            onToggleExpand: () => setState(() => _expanded = !_expanded),
            onTrack: () {},
            onReorder: () {},
          ),
        ],
      ),
    );
  }
}
