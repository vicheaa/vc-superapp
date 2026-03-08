import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/webview/presentation/super_app_webview.dart';
import '../../features/shop/presentation/product_list_screen.dart';

/// Application router configuration using GoRouter.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (context, state) {
           final extra = state.extra;
           if (extra is Map<String, dynamic>) {
               // Load Web App and optionally inject a product
               return SuperAppWebView(
                 url: extra['type'] == 'web_app' ? null : null, 
                 useWebApp: extra['type'] == 'web_app',
                 pendingProductJson: extra['product'] as Map<String, dynamic>?,
               );
           }
           if (extra == 'web_app') {
               return const SuperAppWebView(useWebApp: true);
           }
           final url = extra as String?;
           return SuperAppWebView(url: url);
        },
      ),
      // Add more routes here as features grow:
      //
      // GoRoute(
      //   path: '/login',
      //   name: 'login',
      //   builder: (context, state) => const LoginScreen(),
      // ),
      //
      // GoRoute(
      //   path: '/details/:id',
      //   name: 'details',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return DetailsScreen(id: id);
      //   },
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          '404 — Page not found\n${state.uri}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    ),
  );
}
