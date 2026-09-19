import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/checkout/checkout_draft.dart';
import 'package:matlobgo/screens/home/checkout/checkout_screen.dart';
import 'package:matlobgo/screens/home/checkout/order_confirmation_screen.dart';
import 'package:matlobgo/screens/home/checkout/order_details_screen.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/cart_service.dart';

Route<T> premiumContentRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

Route<T> _premiumRoute<T>(Widget child) => premiumContentRoute<T>(child);

/// Cart → Checkout
Future<void> openCheckoutScreen(
  BuildContext context, {
  required CartService cartService,
  required Governorate governorate,
  required AppUser? user,
  required CheckoutDraft draft,
  VoidCallback? onGoHome,
  VoidCallback? onOrderPlaced,
}) {
  unawaited(
    AnalyticsService.instance.screenView(
      screen: 'checkout',
      label: 'إتمام الطلب',
    ),
  );
  return Navigator.of(context).push(
    _premiumRoute(
      CheckoutScreen(
        cartService: cartService,
        governorate: governorate,
        user: user,
        initialDraft: draft,
        onGoHome: onGoHome,
        onOrderPlaced: onOrderPlaced,
      ),
    ),
  );
}

/// Checkout → Confirmation (استبدال صفحة الدفع)
void openOrderConfirmation(
  BuildContext context, {
  required List<Order> orders,
  required VoidCallback? onGoHome,
  required VoidCallback? onGoOrders,
  String? paymentLabel,
}) {
  Navigator.of(context).pushReplacement(
    _premiumRoute(
      OrderConfirmationScreen(
        orders: orders,
        onGoHome: onGoHome,
        onGoOrders: onGoOrders,
        paymentLabel: paymentLabel,
      ),
    ),
  );
}

/// Checkout success → order details (no driver tracking).
void replaceCheckoutWithTracking(BuildContext context, {required Order order}) {
  unawaited(
    AnalyticsService.instance.screenView(
      screen: 'order_details',
      label: 'تفاصيل ${order.storeName}',
    ),
  );
  Navigator.of(context).pushReplacement(
    _premiumRoute(
      OrderDetailsScreen(order: order),
    ),
  );
}
