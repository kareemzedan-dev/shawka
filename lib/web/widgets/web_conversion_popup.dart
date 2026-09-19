import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';

class WebConversionPopupHost extends StatefulWidget {
  const WebConversionPopupHost({super.key, required this.child});

  final Widget child;

  @override
  State<WebConversionPopupHost> createState() => _WebConversionPopupHostState();
}

class _WebConversionPopupHostState extends State<WebConversionPopupHost> {
  @override
  void initState() {
    super.initState();
    WebConversionService.instance.addListener(_onConversion);
  }

  @override
  void dispose() {
    WebConversionService.instance.removeListener(_onConversion);
    super.dispose();
  }

  void _onConversion() {
    final popup = WebConversionService.instance.pendingPopup;
    if (popup == WebConversionPopupKind.favorites && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showFavoritesPopup();
        await WebConversionService.instance.dismissPopup();
      });
    }
  }

  Future<void> _showFavoritesPopup() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'حمّل التطبيق واحفظ موردينك المفضلين',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'زرت عدة موردين رائعين! في التطبيق يمكنك حفظ المفضلة والطلب بضغطة واحدة.',
          style: GoogleFonts.cairo(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('لاحقاً', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showWebAppConversionModal(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'حمّل التطبيق',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
