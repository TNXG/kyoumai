// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDZz9on-ifIz1oHSLDuIF-HQpIFt8QgQxQ',
    appId: '1:571103832681:web:15ce07be759b648b3290f8',
    messagingSenderId: '571103832681',
    projectId: 'kyoumai233',
    authDomain: 'kyoumai233.firebaseapp.com',
    storageBucket: 'kyoumai233.appspot.com',
    measurementId: 'G-0LYVQSMZZW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDnZ-_UdGlA33eBjJEwzNE_-F99HvAVS_g',
    appId: '1:571103832681:android:a1e782b90c1724803290f8',
    messagingSenderId: '571103832681',
    projectId: 'kyoumai233',
    storageBucket: 'kyoumai233.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAoSE-A2hx_cBr8aPLipNXJboYqEMrSwk',
    appId: '1:571103832681:ios:fe9d977d334a1c093290f8',
    messagingSenderId: '571103832681',
    projectId: 'kyoumai233',
    storageBucket: 'kyoumai233.appspot.com',
    iosBundleId: 'top.tnxg.kyoumai',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCAoSE-A2hx_cBr8aPLipNXJboYqEMrSwk',
    appId: '1:571103832681:ios:fe9d977d334a1c093290f8',
    messagingSenderId: '571103832681',
    projectId: 'kyoumai233',
    storageBucket: 'kyoumai233.appspot.com',
    iosBundleId: 'top.tnxg.kyoumai',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDZz9on-ifIz1oHSLDuIF-HQpIFt8QgQxQ',
    appId: '1:571103832681:web:79d65136d493a0583290f8',
    messagingSenderId: '571103832681',
    projectId: 'kyoumai233',
    authDomain: 'kyoumai233.firebaseapp.com',
    storageBucket: 'kyoumai233.appspot.com',
    measurementId: 'G-1BY1W6S18F',
  );
}
