import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/product_details_screen.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/cart_service.dart';

/// نفس توقيع الدالة القديمة — لا تُغيّر لتبقى المتصلات (home/store) تعمل.
void openProductDetail(
  BuildContext context, {
  required Store store,
  required Product product,
  required List<Product> relatedProducts,
  required CartService cartService,
}) {
  unawaited(
    AnalyticsService.instance.track(
      type: AnalyticsEventType.productView,
      screen: 'product_detail',
      label: 'عرض ${product.name}',
      storeId: store.id,
      storeName: store.name,
      productId: product.id,
      productName: product.name,
    ),
  );
  unawaited(
    AnalyticsService.instance.screenView(
      screen: 'product_detail',
      label: product.name,
    ),
  );
  Navigator.of(context).push(_productRoute(
    store: store,
    product: product,
    relatedProducts: relatedProducts,
    cartService: cartService,
  ));
}

/// فتح منتج مقترح كبديل للشاشة الحالية (نفس المتجر).
void replaceWithProductDetail(
  BuildContext context, {
  required Store store,
  required Product product,
  required List<Product> relatedProducts,
  required CartService cartService,
}) {
  unawaited(
    AnalyticsService.instance.track(
      type: AnalyticsEventType.productView,
      screen: 'product_detail',
      label: 'عرض ${product.name}',
      storeId: store.id,
      storeName: store.name,
      productId: product.id,
      productName: product.name,
    ),
  );
  Navigator.of(context).pushReplacement(_productRoute(
    store: store,
    product: product,
    relatedProducts: relatedProducts,
    cartService: cartService,
  ));
}

Route<void> _productRoute({
  required Store store,
  required Product product,
  required List<Product> relatedProducts,
  required CartService cartService,
}) {
  return PageRouteBuilder<void>(
    transitionDuration: HomeTheme.animStandard,
    reverseTransitionDuration: HomeTheme.animStandard,
    pageBuilder: (_, animation, _) => ProductDetailsScreen(
      store: store,
      product: product,
      relatedProducts: relatedProducts,
      cartService: cartService,
    ),
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.94, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
