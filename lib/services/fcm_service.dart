// lib/services/fcm_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Firebase Cloud Messaging Service
//
// Handles:
// 1. FCM permission requests
// 2. FCM token fetching and registration with backend
// 3. Topic subscription (subscribes all users to 'all_users' topic)
// 4. Foreground message handling → show local notification banner
// 5. Background/terminated notification tap → deep-link navigation
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'local_notification_service.dart';
import 'shared_pref.dart';
import 'package:tobeque/constants/api_constants.dart';

// ── Top-level background message handler ─────────────────────────────────────
// IMPORTANT: This MUST be a top-level function (not a class method).
// It runs in an isolate when the app is terminated or backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  debugPrint('[FCM] Background message received: ${message.messageId}');
  // Note: We don't show local notifications here — FCM handles the system tray
  // notification automatically when the app is in the background/terminated.
}

// ─────────────────────────────────────────────────────────────────────────────

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ── Public: Initialize everything ────────────────────────────────────────

  /// Call this from main.dart after Firebase.initializeApp()
  static Future<void> initialize() async {
    // 1. Register background handler (must be called before other handlers)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Initialize local notifications (for foreground display)
    await LocalNotificationService.initialize(
      onTap: _handleNotificationTap,
    );

    // 3. Request permission from the user
    await _requestPermissions();

    // 4. Get and register the FCM token
    await _registerToken();

    // 5. Subscribe to the global topic — allows broadcast to all users
    await _subscribeToTopics();

    // 6. Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Set up tap handler when app is opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundNotificationTap);

    // 8. Check if app was launched by tapping a terminated-state notification
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App launched from notification tap: ${initialMessage.messageId}');
      // Delay navigation slightly to allow app to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateFromMessage(initialMessage);
    }

    // 9. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      await _saveTokenToBackend(newToken);
    });
  }

  // ── Private: Permission Request ───────────────────────────────────────────

  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  // ── Private: Token Management ─────────────────────────────────────────────

  static Future<void> _registerToken() async {
    try {
      // Get APNS token first on iOS (required before getToken works)
      if (Platform.isIOS) {
        final apnsToken = await _fcm.getAPNSToken();
        debugPrint('[FCM] APNS Token: $apnsToken');
      }

      final String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('[FCM] Device Token: ${token.substring(0, 20)}...');
        await _saveTokenToBackend(token);
      } else {
        debugPrint('[FCM] No FCM token available (emulator or notifications disabled)');
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final authToken = await SharedPrefService.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('[FCM] No auth token — skipping FCM token registration (user not logged in)');
        return;
      }

      final Dio dio = Get.find<Dio>();
      await dio.put(
        '${ApiConstant.apiBase}/user-auth/fcm-token',
        data: {
          'fcmToken': token,
          'devicePlatform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      debugPrint('[FCM] Token successfully registered with backend');
    } catch (e) {
      debugPrint('[FCM] Failed to save token to backend: $e');
      // Non-fatal — will retry on next app launch / token refresh
    }
  }

  // ── Public: Re-register token after login ─────────────────────────────────

  /// Call this after successful user login to ensure the token is registered.
  static Future<void> refreshTokenAfterLogin() async {
    await _registerToken();
  }

  /// Call this on logout to remove the token from backend.
  static Future<void> removeTokenOnLogout() async {
    try {
      final authToken = await SharedPrefService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      final Dio dio = Get.find<Dio>();
      await dio.delete(
        '${ApiConstant.apiBase}/user-auth/fcm-token',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      debugPrint('[FCM] Token removed from backend on logout');
    } catch (e) {
      debugPrint('[FCM] Failed to remove token on logout: $e');
    }
  }

  // ── Private: Topic Subscription ───────────────────────────────────────────

  static Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to 'all_users' — used for broadcast notifications from admin
      await _fcm.subscribeToTopic('all_users');
      debugPrint('[FCM] Subscribed to topic: all_users');

      // Subscribe to platform-specific topics
      if (Platform.isAndroid) {
        await _fcm.subscribeToTopic('android');
      } else if (Platform.isIOS) {
        await _fcm.subscribeToTopic('ios');
      }
    } catch (e) {
      debugPrint('[FCM] Topic subscription error: $e');
    }
  }

  // ── Private: Foreground Message Handler ──────────────────────────────────

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Show a local notification banner (FCM doesn't auto-show when foregrounded)
    await LocalNotificationService.showNotification(
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      imageUrl: notification.android?.imageUrl ?? notification.apple?.imageUrl,
      payload: jsonEncode(message.data),
    );
  }

  // ── Private: Background Tap Handler ─────────────────────────────────────

  static void _handleBackgroundNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Background notification tapped: ${message.notification?.title}');
    _navigateFromMessage(message);
  }

  // ── Private: Local Notification Tap Handler ──────────────────────────────

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigateFromData(data);
    } catch (e) {
      debugPrint('[FCM] Error parsing notification payload: $e');
    }
  }

  // ── Private: Deep-Link Navigation ────────────────────────────────────────

  static void _navigateFromMessage(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  /// Routes user to the correct screen based on the data payload.
  /// Extend this switch as you add more deep-link destinations.
  static void _navigateFromData(Map<String, dynamic> data) {
    try {
      final String screen = data['screen'] ?? 'home';

      switch (screen) {
        case 'product':
          final productId = data['productId'];
          if (productId != null) {
            Get.toNamed('/product-details', arguments: {'productId': productId});
          }
          break;
        case 'category':
          final categoryId = data['categoryId'];
          if (categoryId != null) {
            Get.toNamed('/category', arguments: {'categoryId': categoryId});
          }
          break;
        case 'orders':
          Get.toNamed('/orders');
          break;
        case 'home':
        default:
          // Navigate to home tab — go to root
          Get.offAllNamed('/');
          break;
      }
    } catch (e) {
      debugPrint('[FCM] Navigation error: $e');
    }
  }
}
