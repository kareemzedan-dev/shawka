import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/order_line_item.dart';

Future<void> prepareOrdersGoldens() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

Widget wrapOrdersGolden(Widget child, {Size size = const Size(390, 844)}) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(top: 44, bottom: 34),
        devicePixelRatio: 1,
        textScaler: TextScaler.noScaling,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: child,
        ),
      ),
    ),
  );
}

Order sampleOrdersGoldenOrder({
  OrderStatus status = OrderStatus.preparing,
  int etaMinutes = 15,
  double total = 75,
  double authoritativeGrandTotal = 75,
  double storeRating = 4.8,
  bool storeVerified = true,
  List<OrderLineItem>? lineItems,
}) {
  return Order(
    id: 'ord_8VNX35T7',
    storeName: 'ابو علي',
    category: 'supplier',
    itemsSummary: 'ساندوتش فول',
    itemCount: 3,
    total: total,
    authoritativeGrandTotal: authoritativeGrandTotal,
    status: status,
    createdAt: DateTime(2026, 7, 22, 4),
    etaMinutes: etaMinutes,
    storeRating: storeRating,
    storeVerified: storeVerified,
    deliveryFee: 10,
    paymentMethod: 'cash',
    address: 'شارع التحرير، المنصورة',
    lineItems: lineItems ??
        const [
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
}
