// File generated from the Firebase console web config for project
// hostel-management-8b8dd. Web is configured. Android/iOS will be added once
// those apps are registered in the Firebase console (then update this file).
//
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'Android Firebase options are not configured yet. Register an '
          'Android app in the Firebase console and add its options here.',
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform yet.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkykS0k1J5eZ3CJnROx-pr7GzE9Z3LDZ8',
    appId: '1:641386148699:web:3d58f04d11019d2a9e607e',
    messagingSenderId: '641386148699',
    projectId: 'hostel-management-8b8dd',
    authDomain: 'hostel-management-8b8dd.firebaseapp.com',
    storageBucket: 'hostel-management-8b8dd.firebasestorage.app',
    measurementId: 'G-4GWVT7GLXN',
  );
}
