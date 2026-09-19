import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/debug/cart_preview.dart';
import 'package:matlobgo/models/cart_item.dart';

Future<void> prepareCartGoldens() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

Widget wrapCartGolden(Widget child, {Size size = const Size(390, 844)}) {
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
          backgroundColor: AppColors.background,
          body: child,
        ),
      ),
    ),
  );
}

Product sampleSuggestion() {
  return const Product(
    id: 'p2',
    storeId: 'store_1',
    name: 'بطاطس',
    price: 35,
  );
}

CartItem sampleCartItem({
  String id = 'item_1',
  String name = 'برجر كلاسيك',
  double price = 85,
  int quantity = 2,
  bool available = true,
  bool trackStock = true,
  int stock = 8,
  double discount = 10,
}) {
  return cartPreviewItem(
    id: id,
    name: name,
    price: price,
    quantity: quantity,
    available: available,
    trackStock: trackStock,
    stock: stock,
    discount: discount,
  );
}
