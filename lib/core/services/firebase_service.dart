import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:vc_super_app/core/services/notification_service.dart';

class FirebaseService {
  final NotificationService _notificationService;

  FirebaseService({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  Future<bool> initialize() async {
    try {
      final app = Firebase.app();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // ✅ Ensure user is signed in anonymously (Optional, don't let it block FCM)
      try {
        final auth = FirebaseAuth.instanceFor(app: app);
        final User? user = auth.currentUser;
        if (user == null) {
          debugPrint('FirebaseService: No user, signing in anonymously');
          await auth.signInAnonymously();
          debugPrint('FirebaseService: Signed in anonymously successfully');
        }
      } catch (e) {
        debugPrint('⚠️ FirebaseService: Anonymous sign-in failed: $e');
        debugPrint('   Tip: Ensure "Anonymous" provider is enabled in Firebase Console > Auth > Sign-in method');
      }

      // ✅ Initialize notifications
      await _notificationService.initialize();

      // ✅ Request permissions & get FCM Token
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // ✅ Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FirebaseService: Foreground message received: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      // ✅ Handle notification clicks (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FirebaseService: Notification clicked (background): ${message.messageId}');
      });

      // ✅ Handle notification which launched the app from terminated state
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('FirebaseService: App launched from notification: ${message.messageId}');
        }
      });

      try {
        final token = await messaging.getToken();
        debugPrint('\n\n${'🚀' * 20}');
        debugPrint('🔥 FCM_TOKEN: $token');
        debugPrint('🚀' * 20 + '\n\n');
      } catch (e) {
        debugPrint('❌ Failed to get FCM token: $e');
      }

      debugPrint('FirebaseService: Firebase services initialized successfully');
      return true;
    } catch (e, stack) {
      debugPrint('❌ FirebaseService: Failed to initialize: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null || message.data.isNotEmpty) {
      debugPrint('FirebaseService: Showing foreground notification: ${message.notification?.title}');
      
      final title = message.notification?.title ?? 'No Title';
      final body = message.notification?.body ?? message.data['body'] ?? 'No Body';
      final imageUrl = message.data['imageUrl'] as String? ?? message.notification?.android?.imageUrl;
      final payload = message.data.isNotEmpty ? message.data.toString() : null;

      _notificationService.showNotification(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        imageUrl: imageUrl,
        payload: payload,
      );
    }
  }

  Future<void> printToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('\n\n' + '=' * 50);
      debugPrint('🔥 FCM_TOKEN: $token');
      debugPrint('=' * 50 + '\n\n');
    } catch (e) {
      debugPrint('❌ FirebaseService: Failed to get FCM token: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background Notification: Background message received: ${message.messageId}');

  // Use the NotificationService singleton
  final notificationService = NotificationService();

  if (message.notification != null || message.data.isNotEmpty) {
    debugPrint('Background Notification: Notification Title: ${message.notification?.title}');
    debugPrint('Background Notification: Notification Body: ${message.notification?.body}');
    debugPrint('Background Notification: Data: ${message.data}');
    try {
      final title = message.notification?.title ?? 'No Title';
      final body =
          message.notification?.body ?? message.data['body'] ?? 'No Body';
      final imageUrl =
          message.data['imageUrl'] as String? ??
          message.notification?.android?.imageUrl;
      final payload = message.data.isNotEmpty ? message.data.toString() : null;

      await notificationService.showNotification(
        id:
            message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        imageUrl: imageUrl,
        payload: payload,
      );
      debugPrint('Background Notification: Background notification shown successfully');
    } catch (e) {
      debugPrint('Background Notification: Error in background handler: $e');
    }
  }
}