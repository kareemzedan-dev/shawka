import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/checkout/checkout_navigation.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/screens/home/widgets/order_tracking_widgets.dart';
import 'package:matlobgo/services/theme_service.dart';

void openOrderDetailsScreen(
  BuildContext context, {
  required Order order,
  String? paymentLabel,
}) {
  Navigator.of(context).push(
    premiumContentRoute(
      OrderDetailsScreen(
        order: order,
        paymentLabel: paymentLabel,
      ),
    ),
  );
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.paymentLabel,
  });

  final Order order;
  final String? paymentLabel;

  String _formatDate(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final palette = context.palette;
        final label =
            paymentLabel ?? OrderTrackingUiData.paymentLabel(order);

        return Scaffold(
          backgroundColor: PremiumBackground.scaffoldColor(context),
          appBar: AppBar(
            backgroundColor: PremiumBackground.scaffoldColor(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'تفاصيل الطلب',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: palette.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              HomeTheme.pageHorizontal,
              8,
              HomeTheme.pageHorizontal,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TrackingOrderSummaryCard(
                  order: order,
                  palette: palette,
                  formatDate: _formatDate,
                  paymentLabel: label,
                ),
                const SizedBox(height: 14),
                TrackingPremiumTimeline(
                  status: order.status,
                  palette: palette,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
