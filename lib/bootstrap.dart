import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/di/injection.dart';
import 'core/error/error_handler.dart';
import 'core/services/firebase_service.dart';

/// Shared bootstrap logic used by all flavor entry points.
/// Shared bootstrap logic used by all flavor entry points.
Future<void> bootstrap({required Environment environment}) async {
  GlobalErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ── Environment Configuration ──
    switch (environment) {
      case Environment.dev:
        EnvConfig.initDev();
      case Environment.staging:
        EnvConfig.initStaging();
      case Environment.production:
        EnvConfig.initProduction();
    }

    // ── Global Error Handler Init ──
    GlobalErrorHandler.init();

    // ── Firebase ──
    try {
      await Firebase.initializeApp();
      await FirebaseService.init();
    } catch (e) {
      debugPrint('⚠️ Firebase init failed (missing config?): $e');
      debugPrint('   Add google-services.json / GoogleService-Info.plist to fix.');
    }

    // ── Dependency Injection ──
    await configureDependencies();

    // ── Run App ──
    runApp(const ProviderScope(child: App()));
  });
}
