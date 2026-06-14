

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;











class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCchCqKYa1yFuvJwTYlrJldJ8kR9fo9FrU',
    appId: '1:1062341883201:web:b8c86b9f92eda61985ddc0',
    messagingSenderId: '1062341883201',
    projectId: 'flux-virtual',
    authDomain: 'flux-virtual.firebaseapp.com',
    storageBucket: 'flux-virtual.firebasestorage.app',
    measurementId: 'G-YJJZFCYEHB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClPKsfyEnl9t4bJXu1vr77i7WtJxX782c',
    appId: '1:1062341883201:android:f604ae20dd25bda885ddc0',
    messagingSenderId: '1062341883201',
    projectId: 'flux-virtual',
    storageBucket: 'flux-virtual.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHG8T81hn7bbCYWM3IMItDwYgfw-k_mvs',
    appId: '1:1062341883201:ios:f9860771478189b185ddc0',
    messagingSenderId: '1062341883201',
    projectId: 'flux-virtual',
    storageBucket: 'flux-virtual.firebasestorage.app',
    iosBundleId: 'com.example.fluxVirtual',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBHG8T81hn7bbCYWM3IMItDwYgfw-k_mvs',
    appId: '1:1062341883201:ios:f9860771478189b185ddc0',
    messagingSenderId: '1062341883201',
    projectId: 'flux-virtual',
    storageBucket: 'flux-virtual.firebasestorage.app',
    iosBundleId: 'com.example.fluxVirtual',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCchCqKYa1yFuvJwTYlrJldJ8kR9fo9FrU',
    appId: '1:1062341883201:web:8952b05e12aed2a985ddc0',
    messagingSenderId: '1062341883201',
    projectId: 'flux-virtual',
    authDomain: 'flux-virtual.firebaseapp.com',
    storageBucket: 'flux-virtual.firebasestorage.app',
    measurementId: 'G-2V83S6TKY6',
  );
}
