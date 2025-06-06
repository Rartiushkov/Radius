import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported in this config.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_18I3Az_s8cMcAbESTOnLi3xW6I2Y9bI',
    appId: '1:11371648885:android:d77138a97322d539aba53c',
    messagingSenderId: '11371648885',
    projectId: 'radius-113c4',
    storageBucket: 'radius-113c4.firebasestorage.app',
  );
}
