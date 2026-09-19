// lib/services/local_notification_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Wraps flutter_local_notifications to show rich in-app notification banners
// when a push notification arrives while the app is in the FOREGROUND.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Callback invoked when user taps a local notification
  static void Function(String? payload)? onNotificationTap;

  // ── Android notification channel ──────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tobeque_notifications', // must match AndroidManifest.xml meta-data
    'Tobeque Notifications',
    description: 'Tobeque app push notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize the local notifications plugin.
  /// Call this once at app startup (before runApp or in main.dart).
  static Future<void> initialize({
    void Function(String? payload)? onTap,
  }) async {
    onNotificationTap = onTap;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false, // handled by firebase_messaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // Create the high-importance channel on Android
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Display a notification banner in the foreground.
  static Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
    int id = 0,
  }) async {
    try {
      AndroidNotificationDetails androidDetails;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // With big picture style (image expanded view)
        final BigPictureStyleInformation bigPicture = BigPictureStyleInformation(
          DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: false,
        );

        androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPicture,
          icon: '@mipmap/launcher_icon',
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          styleInformation: BigTextStyleInformation(body),
        );
      }

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[LocalNotification] Error showing notification: $e');
    }
  }

  /// Cancel all displayed local notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
