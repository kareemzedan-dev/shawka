import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/tracking_tokens.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/tracking/tracking_controller.dart';
import 'package:matlobgo/screens/home/tracking/widgets/tracking_driver_card.dart';
import 'package:matlobgo/screens/home/tracking/widgets/tracking_eta_card.dart';
import 'package:matlobgo/screens/home/tracking/widgets/tracking_hero_chrome.dart';
import 'package:matlobgo/screens/home/tracking/widgets/tracking_state_views.dart';
import 'package:matlobgo/screens/home/tracking/widgets/tracking_timeline.dart';
import 'package:matlobgo/screens/home/widgets/driver_rating_sheet.dart';
import 'package:matlobgo/screens/home/widgets/order_tracking_map.dart';
import 'package:matlobgo/screens/home/widgets/order_tracking_widgets.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/services/theme_service.dart';

/// نقطة الدخول العامة — تحافظ على التوقيع الحالي.
void openOrderTracking(
  BuildContext context, {
  required Order order,
  OrderService? orderService,
}) {
  unawaited(
    AnalyticsService.instance.screenView(
      screen: 'order_tracking',
      label: 'تتبع ${order.storeName}',
    ),
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OrderTrackingScreen(
        order: order,
        orderService: orderService ?? OrderService.instance,
      ),
    ),
  );
}

/// شاشة تتبع الطلب — تكوين رفيع (RI v7).
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.order,
    required this.orderService,
  });

  final Order order;
  final OrderService orderService;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late final TrackingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TrackingController(
      initialOrder: widget.order,
      orderService: widget.orderService,
    );
    _controller.addListener(_onController);
  }

  void _onController() {
    if (_controller.order.canRateDriver && !_controller.ratingPrompted) {
      _controller.markRatingPrompted();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showDriverRatingSheet(context, order: _controller.order);
      });
    }
    final notice = _controller.notice;
    if (notice != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              notice,
              style: CartTypography.style(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.navy,
          ),
        );
      _controller.clearNotice();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (!_controller.order.canCustomerCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن إلغاء الطلب في هذه المرحلة',
            style: CartTypography.style(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إلغاء الطلب',
          style: CartTypography.style(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء هذا الطلب؟',
          style: CartTypography.style(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _controller.cancel();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: CartTypography.style(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _reorder() async {
    final added = await _controller.reorder();
    if (!mounted) return;
    if (added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر إعادة الطلب — تحقق من توفر المنتجات',
            style: CartTypography.style(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إضافة $added عنصر للسلة',
          style: CartTypography.style(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, ThemeService.instance]),
      builder: (context, _) {
        final palette = context.palette;
        final order = _controller.order;
        final snapshot = _controller.snapshot;
        final phase = _controller.phase;
        final top = MediaQuery.paddingOf(context).top;
        final mapHeight =
            (MediaQuery.sizeOf(context).height * 0.42).clamp(280.0, 420.0);
        final platform = Theme.of(context).platform;
        final useMaps = platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;
        final showDriverCard = order.status != OrderStatus.cancelled &&
            (order.hasAssignedDriver ||
                phase == TrackingUiPhase.waitingDriver ||
                order.status == OrderStatus.preparing ||
                order.status == OrderStatus.readyForPickup ||
                order.status == OrderStatus.onTheWay ||
                order.status == OrderStatus.delivered);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: palette.isDark
              ? SystemUiOverlayStyle.light
              : AppColors.lightStatusBar,
          child: Scaffold(
            backgroundColor: PremiumBackground.scaffoldColor(context),
            body: Column(
              children: [
                SizedBox(
                  height: mapHeight + top,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: useMaps
                            ? OrderTrackingMap(
                                snapshot: snapshot,
                                palette: palette,
                                storeName: order.storeName,
                                followDriver: _controller.followDriver,
                              )
                            : OrderTrackingMapPlaceholder(
                                snapshot: snapshot,
                                palette: palette,
                              ),
                      ),
                      PositionedDirectional(
                        top: top + 10,
                        start: TrackingTokens.pagePadding,
                        child: TrackingBackButton(
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      Positioned(
                        top: top + 10,
                        left: 64,
                        right: 64,
                        child: TrackingMapHero(
                          title: 'تتبع الطلب',
                          subtitle: order.storeName.trim().isNotEmpty
                              ? order.storeName
                              : '#${order.id}',
                        ),
                      ),
                      PositionedDirectional(
                        top: top + 10,
                        end: TrackingTokens.pagePadding,
                        child: TrackingLiveBadge(
                          active: _controller.showLiveBadge,
                        ),
                      ),
                      if (snapshot.showDriver || snapshot.isLiveDeliveryMode)
                        PositionedDirectional(
                          top: top + 62,
                          end: TrackingTokens.pagePadding,
                          child: Material(
                            color: Colors.white,
                            elevation: 0,
                            shape: const CircleBorder(),
                            shadowColor: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _controller.toggleFollowDriver,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: TrackingTokens.floatingShadow,
                                ),
                                child: Icon(
                                  _controller.followDriver
                                      ? Icons.near_me_rounded
                                      : Icons.near_me_outlined,
                                  size: 18,
                                  color: TrackingTokens.navy,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -22),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: TrackingTokens.sheetBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(TrackingTokens.sheetRadius),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: TrackingTokens.cardBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(
                            child: phase == TrackingUiPhase.loading
                                ? const TrackingLoadingSheet()
                                : ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      24,
                                    ),
                                    children: [
                                      TrackingPhaseBanner(phase: phase),
                                      TrackingEtaSheetCard(
                                        order: order,
                                        snapshot: snapshot,
                                      ),
                                      const SizedBox(height: 18),
                                      TrackingVerticalTimeline(order: order),
                                      const SizedBox(height: 18),
                                      if (showDriverCard)
                                        TrackingDriverSheetCard(
                                          driver: _controller.driverInfo,
                                          waiting: !order.hasAssignedDriver &&
                                              order.status !=
                                                  OrderStatus.delivered,
                                          onCall: () {
                                            final phone = _controller
                                                    .driverInfo?.phone ??
                                                '';
                                            if (phone.trim().length >= 10) {
                                              unawaited(
                                                trackingCallDriver(phone),
                                              );
                                            }
                                          },
                                          onChat: () {
                                            final phone = _controller
                                                    .driverInfo?.phone ??
                                                '';
                                            if (phone.trim().length >= 10) {
                                              unawaited(
                                                trackingMessageDriver(phone),
                                              );
                                            }
                                          },
                                        ),
                                      if (order.canCustomerCancel) ...[
                                        const SizedBox(height: 16),
                                        OutlinedButton(
                                          onPressed: _cancel,
                                          style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(48),
                                            foregroundColor:
                                                CartTokens.dangerText,
                                            side: const BorderSide(
                                              color: CartTokens.dangerText,
                                            ),
                                          ),
                                          child: const Text('إلغاء الطلب'),
                                        ),
                                      ],
                                      if (order.status ==
                                          OrderStatus.delivered) ...[
                                        const SizedBox(height: 16),
                                        FilledButton(
                                          onPressed: _reorder,
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(48),
                                            backgroundColor:
                                                TrackingTokens.accent,
                                          ),
                                          child: const Text('إعادة الطلب'),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
