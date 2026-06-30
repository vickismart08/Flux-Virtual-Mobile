import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {},
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'flux_virtual_channel',
          'Flux Virtual Notifications',
          description: 'Notifications for calls and messages',
          importance: Importance.high,
        ));

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(
        title: message.notification?.title ?? 'Flux Virtual',
        body: message.notification?.body ?? '',
      );
    });

    // When FCM issues a new token, update Firestore immediately
    _messaging.onTokenRefresh.listen((newToken) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _saveTokenToFirestore(uid, newToken);
      }
    });
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flux_virtual_channel',
          'Flux Virtual Notifications',
          channelDescription: 'Notifications for calls and messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Save FCM token to Firestore + subscribe to topics ───────
  static Future<void> saveToken(String uid) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Must have APNS token before FCM token is available on iOS
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 2));
        }
        if (apnsToken == null) {
          debugPrint('FCM: APNS token unavailable after retries');
          return;
        }
        debugPrint('FCM: APNS token ready');
      }

      final fcmToken = await _messaging.getToken();
      debugPrint('FCM token: $fcmToken');

      if (fcmToken != null) {
        await _saveTokenToFirestore(uid, fcmToken);
      }

      // Topics as an additional fallback
      await _messaging.subscribeToTopic('user_$uid');
      await _messaging.subscribeToTopic('all_users');
      debugPrint('FCM: setup complete for $uid');
    } catch (e) {
      debugPrint('FCM saveToken error: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM: token saved to Firestore');
    } catch (e) {
      debugPrint('FCM: Firestore token save error: $e');
    }
  }
}
