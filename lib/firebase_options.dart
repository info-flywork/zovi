// File generated from Firebase config (android/app/google-services.json +
// ios/Runner/GoogleService-Info.plist). Prefer `flutterfire configure` when
// adding web/macos/windows targets.
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYqABsPsbJFR2Kj2WszVePoRgzzL2Jvbs',
    appId: '1:226127781305:android:4cb39b4123a70887b22a68',
    messagingSenderId: '226127781305',
    projectId: 'zovi-7a4a7',
    storageBucket: 'zovi-7a4a7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2r46ATz4G6vAGB-_Y0L1EMsJZAAhUoFs',
    appId: '1:226127781305:ios:b3f88cc440b4be96b22a68',
    messagingSenderId: '226127781305',
    projectId: 'zovi-7a4a7',
    storageBucket: 'zovi-7a4a7.firebasestorage.app',
    iosBundleId: 'com.flywork.zovi',
  );
}
