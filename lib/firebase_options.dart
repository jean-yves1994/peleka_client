// PLACEHOLDER — replace by running `flutterfire configure`.
// main.dart wraps Firebase.initializeApp in try/catch so these placeholder
// values won't crash the app; phone OTP just won't work until you configure.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _p;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return _p;
      case TargetPlatform.iOS: return _pIos;
      default: return _p;
    }
  }
  static const _p = FirebaseOptions(
    apiKey: 'REPLACE_ME', appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000', projectId: 'peleka-kigali',
    storageBucket: 'peleka-kigali.appspot.com');
  static const _pIos = FirebaseOptions(
    apiKey: 'REPLACE_ME', appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000', projectId: 'peleka-kigali',
    storageBucket: 'peleka-kigali.appspot.com', iosBundleId: 'com.example.peleka_client');
}
