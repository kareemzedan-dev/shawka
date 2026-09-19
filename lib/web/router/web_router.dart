import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/web/screens/web_product_screen.dart';
import 'package:matlobgo/web/v2/screens/tarfa_category_screen.dart';
import 'package:matlobgo/web/v2/screens/tarfa_home_screen.dart';
import 'package:matlobgo/web/v2/screens/tarfa_search_screen.dart';
import 'package:matlobgo/web/screens/web_store_screen.dart';
import 'package:matlobgo/web/v2/screens/tarfa_profile_screen.dart';
import 'package:matlobgo/web/v2/screens/tarfa_stores_screen.dart';
import 'package:matlobgo/web/v2/services/tarfa_cart_drawer_controller.dart';
import 'package:matlobgo/web/v2/shell/tarfa_shell.dart';

final rootWebNavigatorKey = GlobalKey<NavigatorState>();
GoRouter createWebRouter() {
  return GoRouter(
    navigatorKey: rootWebNavigatorKey,
    initialLocation: '/g/cairo',
    routes: [
      ShellRoute(
        builder: (context, state, child) => TarfaShell(
          state: state,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, _) => '/g/cairo',
          ),
          GoRoute(
            path: '/g/:govId',
            builder: (context, state) => TarfaHomeScreen(
              govId: state.pathParameters['govId'],
            ),
          ),
          GoRoute(
            path: '/g/:govId/stores',
            builder: (context, state) => TarfaStoresScreen(
              govId: state.pathParameters['govId']!,
            ),
          ),
          GoRoute(
            path: '/g/:govId/search',
            builder: (context, state) => TarfaSearchScreen(
              govId: state.pathParameters['govId']!,
              initialQuery: state.uri.queryParameters['q'] ?? '',
            ),
          ),
          GoRoute(
            path: '/g/:govId/profile',
            builder: (context, state) => TarfaProfileScreen(
              govId: state.pathParameters['govId'],
            ),
          ),
          GoRoute(
            path: '/g/:govId/category/:categoryId',
            builder: (context, state) => TarfaCategoryScreen(
              govId: state.pathParameters['govId']!,
              categoryId: state.pathParameters['categoryId']!,
            ),
          ),
          GoRoute(
            path: '/store/:storeId',
            builder: (context, state) => WebStoreScreen(
              storeId: state.pathParameters['storeId']!,
            ),
          ),
          GoRoute(
            path: '/store/:storeId/product/:productId',
            builder: (context, state) => WebProductScreen(
              storeId: state.pathParameters['storeId']!,
              productId: state.pathParameters['productId']!,
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                TarfaCartDrawerController.instance.open();
              });
              return const TarfaHomeScreen(govId: 'cairo');
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('الصفحة غير موجودة: ${state.uri}')),
    ),
  );
}
