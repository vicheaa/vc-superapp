import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/di/injection.dart';
import 'core/error/error_handler.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/popup_service.dart';

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

    // ── Notifications ──
    debugPrint('Bootstrap: Init Notifications started');
    await NotificationService().initialize();
    debugPrint('Bootstrap: Init Notifications finished');

    // ── Firebase ──
    try {
      debugPrint('Bootstrap: Init Firebase started');
      await Firebase.initializeApp();
      debugPrint('Bootstrap: Init Firebase finished');
      
      debugPrint('Bootstrap: Calling FirebaseService.initialize()');
      final firebaseService = FirebaseService(notificationService: NotificationService());
      await firebaseService.initialize();
      debugPrint('Bootstrap: FirebaseService.initialize() finished');

      // ── In-App Popups ──
      debugPrint('Bootstrap: Calling PopupService.initialize()');
      await PopupService.instance.initialize();
      debugPrint('Bootstrap: PopupService.initialize() finished');
    } catch (e, stack) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('Stack trace: $stack');
      debugPrint('   Check if google-services.json (Android) or GoogleService-Info.plist (iOS) is present and matches the current flavor/bundle ID.');
    }

    // ── Dependency Injection ──
    debugPrint('Bootstrap: Init DI started');
    await configureDependencies();
    debugPrint('Bootstrap: Init DI finished');

    // ── Run App ──
    debugPrint('Bootstrap: Running App()');
    runApp(const ProviderScope(child: App()));
  });
}
