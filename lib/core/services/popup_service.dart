import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter/foundation.dart';

class PopupService {
  PopupService._();

  static final PopupService instance = PopupService._();
  
  final FirebaseInAppMessaging _fiam = FirebaseInAppMessaging.instance;

  Future<void> initialize() async {
    debugPrint('PopupService: Initializing In-App Messaging...');
    await _printInstallationId();
  }

  Future<void> _printInstallationId() async {
    try {
      final String id = await FirebaseInstallations.instance.getId();
      debugPrint('\n\n${'✨' * 20}');
      debugPrint('🔥 FIAM Installation ID (FID): $id');
      debugPrint('✨' * 20 + '\n\n');
      debugPrint('Use this ID in Firebase Console > In-App Messaging > "Test on device" to see popups immediately.');
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        debugPrint('\n\n${'⚠️' * 20}');
        debugPrint('PopupService: MissingPluginException detected.');
        debugPrint('To fix this, you MUST perform a COLD RESTART:');
        debugPrint('1. Click the red "Stop" button in your IDE.');
        debugPrint('2. Run "flutter run" again.');
        debugPrint('Hot Reload/Restart is NOT enough when adding new plugins.');
        debugPrint('⚠️' * 20 + '\n\n');
      } else {
        debugPrint('❌ PopupService: Failed to get Installation ID: $e');
      }
    }
  }

  /// Trigger a custom event to show a popup.
  Future<void> triggerEvent(String eventName) async {
    if (kDebugMode) {
      debugPrint('PopupService: Triggering event: $eventName');
    }
    await _fiam.triggerEvent(eventName);
  }

  /// Temporarily suppress or allow In-App Messages.
  Future<void> setMessagesSuppressed(bool suppressed) async {
    if (kDebugMode) {
      debugPrint('PopupService: Setting messages suppressed: $suppressed');
    }
    await _fiam.setMessagesSuppressed(suppressed);
  }
}