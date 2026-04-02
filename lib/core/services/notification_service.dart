import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static Map<String, dynamic>? _payload;

  NotificationService._internal();

  factory NotificationService() => _instance;

  void setPayload(dynamic payload) {
    _payload = payload is Map<String, dynamic> ? payload : null;
    if (kDebugMode) {
      debugPrint('NotificationService: Payload set: $_payload');
    }
  }

  Map<String, dynamic>? getPayload() => _payload;

  Future<void> initialize() async {
    if (_notificationsPlugin != null) {
      if (kDebugMode) {
        debugPrint('NotificationService: Already initialized, skipping');
      }
      return;
    }
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestBadgePermission: true,
          requestSoundPermission: true,
          defaultPresentSound: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    try {
      final androidPlugin = _notificationsPlugin!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await _notificationsPlugin!.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (kDebugMode) {
          debugPrint(
            'NotificationService: Permissions ${granted == true ? 'granted' : 'denied'}',
          );
        }
      }

      if (kDebugMode) {
        debugPrint('NotificationService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error initializing: $e');
      }
      rethrow;
    }
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print(
        'NotificationService: Notification tapped with payload: ${response.payload}',
      );
      if (_payload != null) {
        print('NotificationService: Processing payload: $_payload');
      }
    }
  }

  Future<NotificationDetails> _notificationDetails({String? imageUrl}) async {
    if (Platform.isAndroid && imageUrl != null && imageUrl.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('NotificationService: Processing image URL: $imageUrl');
        }
        final filePath = await _downloadAndSaveFile(
          imageUrl,
          'notification_image_${DateTime.now().millisecondsSinceEpoch}',
        );
        final bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: 'Image Notification',
          summaryText: 'Image included',
        );

        return NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: bigPictureStyle,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(presentSound: true),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: Failed to process image: $e');
        }
      }
    }

    if (kDebugMode && imageUrl == null) {
      debugPrint(
        'NotificationService: No image URL provided, using basic notification',
      );
    }
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );
  }

  Future<void> showNotification({
    required int id,
    String? title,
    String? body,
    String? imageUrl,
    String? payload,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('NotificationService: Preparing to show notification:');
        debugPrint('  ID: $id');
        debugPrint('  Title: $title');
        debugPrint('  Body: $body');
        debugPrint('  Image URL: $imageUrl');
        debugPrint('  Payload: $payload');
      }
      final details = await _notificationDetails(imageUrl: imageUrl);
      await _notificationsPlugin!.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Notification displayed: $title - $body - $imageUrl',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error displaying notification: $e');
      }
      final fallbackDetails = await _notificationDetails();
      await _notificationsPlugin!.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: fallbackDetails,
        payload: payload,
      );
      if (kDebugMode) {
        debugPrint(
          'NotificationService: Fallback notification displayed: $title - $body',
        );
      }
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    try {
      if (kDebugMode) {
        debugPrint('NotificationService: Starting image download from: $url');
      }
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      if (kDebugMode) {
        debugPrint('NotificationService: Image downloaded to: $filePath');
      }
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: Error downloading image: $e');
      }
      rethrow;
    }
  }
}