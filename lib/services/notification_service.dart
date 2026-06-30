import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Background handler — the OS already shows the notification automatically
// because FCM messages include a `notification` payload. This handler is
// kept only to satisfy the FirebaseMessaging.onBackgroundMessage requirement.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty — do NOT call showLocalNotification here.
  // The system notification is already shown by the OS from the FCM payload.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ── Initialize ───────────────────────────────────────────
  static Future<void> initialize() async {
    // request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: allow FCM notifications to show while app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // setup local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // Permissions are already requested above via FirebaseMessaging.requestPermission.
    // Setting these to false prevents a second native iOS dialog from appearing.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
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
    // Foreground messages: the OS does NOT auto-show these, so we display
    // a local notification manually. Background messages are handled by
    // firebaseMessagingBackgroundHandler (registered in main.dart).
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(
        title: message.notification?.title ?? 'Flux Virtual',
        body: message.notification?.body ?? '',
      );
    });
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

  // ── Subscribe user to their FCM topics ──────────────────────
  static Future<void> saveToken(String uid) async {
    try {
      // On iOS, topic subscription silently fails if the APNS token isn't
      // ready yet. Wait for it before subscribing.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 2));
        }
        if (apnsToken == null) return;
      }
      await _messaging.subscribeToTopic('user_$uid');
      await _messaging.subscribeToTopic('all_users');
    } catch (_) {}
  }
}
