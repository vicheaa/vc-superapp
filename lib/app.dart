import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: false,

        // ── Theme ──
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,

        // ── Router ──
        routerConfig: AppRouter.router,

        // ── Flavor Banner Overlay ──
        builder: (context, child) {
          if (EnvConfig.isProduction) return child!;

          return Directionality(
            textDirection: TextDirection.ltr,
            child: Banner(
              color: EnvConfig.isDev ? Colors.red : Colors.orange,
              message: EnvConfig.isDev ? 'DEV' : 'STAGING',
              location: BannerLocation.topStart,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
