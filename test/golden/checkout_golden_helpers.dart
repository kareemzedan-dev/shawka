import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

Future<void> prepareCheckoutGoldens() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

Widget wrapCheckoutGolden(Widget child, {Size size = const Size(390, 844)}) {
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
