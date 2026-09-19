import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/checkout/checkout_ui_data.dart';
import 'package:matlobgo/screens/home/checkout/order_confirmation_widgets.dart';
import 'package:matlobgo/screens/home/checkout/order_details_screen.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/services/theme_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orders,
    this.onGoHome,
    this.onGoOrders,
    this.paymentLabel,
  });

  final List<Order> orders;
  final VoidCallback? onGoHome;
  final VoidCallback? onGoOrders;
  final String? paymentLabel;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _contentController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _pulse;
  late final Animation<double> _checkProgress;

  Order get _primary => widget.orders.first;

  String get _paymentLabel =>
      widget.paymentLabel ?? OrderTrackingUiData.paymentLabel(_primary);

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _scale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.35), weight: 45),
    ]).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
      ),
    );
    _checkProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.35, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _heroController.forward();
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _contentController.forward();
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onGoHome?.call();
  }

  void _viewDetails() {
    openOrderDetailsScreen(
      context,
      order: _primary,
      paymentLabel: _paymentLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final palette = context.palette;
        final eta = OrderTrackingUiData.build(_primary).etaMinutes;
        final orderId = CheckoutUiData.formatOrderId(_primary.id);
        final bottom = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          backgroundColor: PremiumBackground.scaffoldColor(context),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OrderSuccessHero(
                                  scale: _scale,
                                  fade: _fade,
                                  pulse: _pulse,
                                  checkProgress: _checkProgress,
                                  palette: palette,
                                ),
                                const SizedBox(height: 20),
                                OrderConfirmationReveal(
                                  animation: _contentController,
                                  interval: const Interval(0, 0.55,
                                      curve: Curves.easeOut),
                                  child: Column(
                                    children: [
                                      Text(
                                        '✓ تم تأكيد طلبك بنجاح',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'رقم الطلب #$orderId',
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (widget.orders.length > 1) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '${widget.orders.length} طلبات من متاجر مختلفة',
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OrderConfirmationReveal(
                                  animation: _contentController,
                                  interval: const Interval(0.12, 0.72,
                                      curve: Curves.easeOut),
                                  child: OrderConfirmationSummaryCard(
                                    order: _primary,
                                    palette: palette,
                                    paymentLabel: _paymentLabel,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OrderConfirmationReveal(
                                  animation: _contentController,
                                  interval: const Interval(0.28, 0.88,
                                      curve: Curves.easeOut),
                                  child: OrderConfirmationEtaCard(
                                    etaMinutes: eta,
                                    palette: palette,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  OrderConfirmationReveal(
                    animation: _contentController,
                    interval: const Interval(0.45, 1, curve: Curves.easeOut),
                    slideOffset: 0.05,
                    child: Column(
                      children: [
                        OrderConfirmationButton(
                          label: 'عرض تفاصيل الطلب',
                          onPressed: _viewDetails,
                          palette: palette,
                          style: OrderConfirmationButtonStyle.primary,
                        ),
                        const SizedBox(height: 6),
                        OrderConfirmationButton(
                          label: 'العودة للرئيسية',
                          onPressed: _goHome,
                          palette: palette,
                          style: OrderConfirmationButtonStyle.tertiary,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: bottom > 0 ? bottom - 4 : 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
