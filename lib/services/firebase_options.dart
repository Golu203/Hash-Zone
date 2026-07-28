import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for project 'hashzone'.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDa81GMeWNHzjV3nUpbXMOeTBT-nQjxxcg',
    appId: '1:515632255937:web:bf3d15e85c8d2d0e399540',
    messagingSenderId: '515632255937',
    projectId: 'hashzone',
    authDomain: 'hashzone.firebaseapp.com',
    storageBucket: 'hashzone.firebasestorage.app',
    measurementId: 'G-65HXPVEH6M',
  );
}
