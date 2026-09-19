import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/web/router/web_router.dart';
import 'package:matlobgo/web/v2/design/tarfa_theme.dart';

class MatlobGoWebApp extends StatefulWidget {
  const MatlobGoWebApp({super.key});

  @override
  State<MatlobGoWebApp> createState() => _MatlobGoWebAppState();
}

class _MatlobGoWebAppState extends State<MatlobGoWebApp> {
  late final _router = createWebRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppBranding.shortName,
      debugShowCheckedModeBanner: false,
      theme: TarfaTheme.light,
      locale: const Locale('ar'),
      routerConfig: _router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
