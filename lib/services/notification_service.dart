import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Flux Virtual',
    body: message.notification?.body ?? '',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ── Initialize ───────────────────────────────────────────
  static Future<void> initialize() async {
    // request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // setup local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // handle notification tap
      },
    );

    // create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'flux_virtual_channel',
      'Flux Virtual Notifications',
      description: 'Notifications for calls and messages',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(
        title: message.notification?.title ?? 'Flux Virtual',
        body: message.notification?.body ?? '',
      );
    });

    // background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ── Show local notification ──────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'flux_virtual_channel',
      'Flux Virtual Notifications',
      channelDescription: 'Notifications for calls and messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ── Get FCM token ────────────────────────────────────────
  // ── Get FCM token ────────────────────────────────────────────
  static Future<String?> getToken() async {
    try {
      // iOS requires APNS token first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) return null; // simulator — skip
      }
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  // ── Save token to Firestore ──────────────────────────────────
  static Future<void> saveToken(String uid) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _messaging.subscribeToTopic('user_$uid');
        await _messaging.subscribeToTopic(
          'all_users',
        ); // ✅ subscribe to all users topic
      }
    } catch (_) {}
  }
}
