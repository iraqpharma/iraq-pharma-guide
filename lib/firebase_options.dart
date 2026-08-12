// File generated manually to support CI builds without Xcode/macOS.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPtqSY3qprNWHQHPeoDocz5f1lSQBQ2Bc',
    appId: '1:1411929971:android:a5b4a249f0c6ff3c449706',
    messagingSenderId: '1411929971',
    projectId: 'iraq-pharma-guide',
    storageBucket: 'iraq-pharma-guide.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHU9cebiVZx82-0Uu_emjh1mJtRBUhO7c',
    appId: '1:1411929971:ios:46ed9fd46f212ed9449706',
    messagingSenderId: '1411929971',
    projectId: 'iraq-pharma-guide',
    storageBucket: 'iraq-pharma-guide.firebasestorage.app',
    iosBundleId: 'com.iraqpharmaguide.iraqPharmaGuide',
  );
}
