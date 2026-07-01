import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Auth/splash_screen.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/firebase_options.dart';
import 'package:flux_virtual/services/keep_alive_service.dart';
import 'package:flux_virtual/services/notification_service.dart';
import 'package:flux_virtual/services/remote_config_service.dart';
import 'package:flux_virtual/services/voice_service.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();
  // saveToken() is called inside SplashScreen after Flutter engine is fully ready

  await RemoteConfigService.initialize();
  KeepAliveService.start();

  // Request READ_PHONE_NUMBERS permission, register the Android phone account,
  // and open Settings if the user hasn't enabled it yet (one-time setup).
  await VoiceService.setupAndroid();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) NotificationService.saveToken(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux Virtual',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.mode,
      home: const SplashScreen(),
    );
  }
}
