import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/webview/presentation/super_app_webview.dart';

import '../../features/profile/presentation/profile_screen.dart';
// [GENERATED_IMPORTS_ROUTER]

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Application router configuration using GoRouter and Riverpod.
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(false);
  
  ref.onDispose(() {
    listenable.dispose();
  });

  ref.listen<AsyncValue<AuthState>>(authProvider, (_, _) {
    listenable.value = !listenable.value;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: listenable,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authStateAsync = ref.read(authProvider);

      if (authStateAsync.isLoading || !authStateAsync.hasValue) {
         // Stay on splash while initializing
         return null; 
      }

      final authState = authStateAsync.value!;
      final isAuth = authState.status == AuthStatus.authenticated;
      final isGoingToSplash = state.uri.toString() == '/splash';
      final isGoingToLogin = state.uri.toString() == '/login';
      final isAdminRoute = state.uri.toString().startsWith('/admin');
      
      // If unauthenticated and not going to login, redirect away from home/protected routes
      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }
      
      // If authenticated and trying to go to login or splash, redirect to home
      if (isAuth && (isGoingToLogin || isGoingToSplash)) {
        return '/';
      }

      // If unauthenticated and on splash, go to login
      if (!isAuth && isGoingToSplash) {
        return '/login';
      }

      // Check RBAC
      if (isAdminRoute && isAuth) {
         if (authState.user?.isAdmin != true) {
            return '/'; // fallback, not authorized
         }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (context, state) {
           final extra = state.extra;
           if (extra is Map<String, dynamic>) {
               if (extra.containsKey('localHtmlFilePath')) {
                 return SuperAppWebView(
                   localHtmlFilePath: extra['localHtmlFilePath'] as String,
                   title: extra['title'] as String?,
                 );
               }
               
               // Load Web App and optionally inject a product
               return SuperAppWebView(
                 url: extra['type'] == 'web_app' ? null : null, 
                 miniAppId: extra['type'] == 'web_app' ? 'shop' : null,
                 pendingProductJson: extra['product'] as Map<String, dynamic>?,
               );
           }
           if (extra == 'web_app') {
               return const SuperAppWebView(miniAppId: 'shop');
           }
           final url = extra as String?;
           return SuperAppWebView(url: url);
        },
      ),
      
            GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // [GENERATED_ROUTES_ROUTER]
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
});
