import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// Top-level handler for Firebase Messaging background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info(
    'Background message: ${message.messageId}',
    tag: 'FCM',
  );
}

/// Centralized Firebase service for initialization and common operations.
class FirebaseService {
  FirebaseService._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// Initialize all Firebase services.
  /// Call this after `Firebase.initializeApp()`.
  static Future<void> init() async {
    // ── Crashlytics ──
    await _initCrashlytics();

    // ── Analytics ──
    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

    // ── FCM ──
    await _initMessaging();

    AppLogger.info('Firebase services initialized', tag: 'FIREBASE');
  }

  // ──── Crashlytics ────

  static Future<void> _initCrashlytics() async {
    // Disable Crashlytics in debug mode
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Pass uncaught async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Report a non-fatal error to Crashlytics.
  static Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason ?? 'Non-fatal error',
      fatal: fatal,
    );
  }

  /// Set user identifier for Crashlytics.
  static Future<void> setUserId(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    await analytics.setUserId(id: userId);
  }

  /// Log a custom Crashlytics key-value pair.
  static Future<void> setCustomKey(String key, Object value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  // ──── FCM ────

  static Future<void> _initMessaging() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Request permission (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info(
      'FCM authorization: ${settings.authorizationStatus}',
      tag: 'FCM',
    );

    // Get FCM token
    final token = await messaging.getToken();
    AppLogger.info('FCM token: $token', tag: 'FCM');

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      AppLogger.info('FCM token refreshed: $newToken', tag: 'FCM');
      // TODO: Send token to your backend
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(
        'Foreground message: ${message.notification?.title}',
        tag: 'FCM',
      );
      // TODO: Show local notification or in-app banner
    });

    // Handle notification tap when app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info(
        'Notification tap (background): ${message.data}',
        tag: 'FCM',
      );
      // TODO: Navigate to relevant screen
    });
  }

  /// Get the current FCM token.
  static Future<String?> getToken() => messaging.getToken();

  // ──── Analytics ────

  /// Log a custom analytics event.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log a screen view event.
  static Future<void> logScreenView(String screenName) async {
    await analytics.logScreenView(screenName: screenName);
  }
}
