import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'token_service.dart';

/// Top-level handler required by firebase_messaging for background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray automatically.
  // No additional work needed unless you need to write to local DB.
}

/// Service that initialises Firebase Cloud Messaging, requests permissions,
/// obtains the FCM device token, registers it with the backend, and forwards
/// foreground messages to flutter_local_notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialise local notifications for foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create notification channel for Android
    if (!kIsWeb) {
      const channel = AndroidNotificationChannel(
        'aqari_high_importance',
        'Aqari Notifications',
        description: 'Application status updates and property alerts',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Show foreground notifications
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Register current token with backend
    final token = await _fcm.getToken();
    if (token != null) await _registerToken(token);

    // Re-register if token is refreshed
    _fcm.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    try {
      final accessToken = await TokenService.getAccessToken();
      if (accessToken == null) return;
      await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/fcm-token'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcmToken': token}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Non-critical — will retry on next launch
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'aqari_high_importance',
          'Aqari Notifications',
          channelDescription: 'Application status updates and property alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Call on logout to clear the FCM token from the backend.
  Future<void> clearToken() async {
    try {
      final accessToken = await TokenService.getAccessToken();
      if (accessToken == null) return;
      await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/fcm-token'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcmToken': null}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[NotificationService] clearToken error: $e');
    }
  }
}
