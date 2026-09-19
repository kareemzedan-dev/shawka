import 'package:flutter/material.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/widgets/admin_gate.dart';
import 'package:matlobgo/core/constants/app_branding.dart';

class MatlobGoAdminApp extends StatelessWidget {
  const MatlobGoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.adminPanelTitle,
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AdminGate(),
    );
  }
}
