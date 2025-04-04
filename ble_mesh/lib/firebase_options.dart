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
    apiKey: 'AIzaSyDLLC1a4Nm9bNGIuAypmcgQvmmBEZIYFuw',
    appId: '1:743465184716:web:270c54411254fff07d0169',
    messagingSenderId: '743465184716',
    projectId: 'noderedfirebase-769cf',
    authDomain: 'noderedfirebase-769cf.firebaseapp.com',
    databaseURL: 'https://noderedfirebase-769cf-default-rtdb.firebaseio.com',
    storageBucket: 'noderedfirebase-769cf.appspot.com',
    measurementId: 'G-V6SVQH6525',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8Nhkr92fVjhJL7YzLyJX5gyhFR5wIJ-0',
    appId: '1:743465184716:android:e3d54c10a60fdbaa7d0169',
    messagingSenderId: '743465184716',
    projectId: 'noderedfirebase-769cf',
    databaseURL: 'https://noderedfirebase-769cf-default-rtdb.firebaseio.com',
    storageBucket: 'noderedfirebase-769cf.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAuvkVQMGm9n9aor7Tt068-hms3oZkfA7A',
    appId: '1:743465184716:ios:3dcc8a3e6826b49f7d0169',
    messagingSenderId: '743465184716',
    projectId: 'noderedfirebase-769cf',
    databaseURL: 'https://noderedfirebase-769cf-default-rtdb.firebaseio.com',
    storageBucket: 'noderedfirebase-769cf.appspot.com',
    iosBundleId: 'com.example.bleMesh',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAuvkVQMGm9n9aor7Tt068-hms3oZkfA7A',
    appId: '1:743465184716:ios:3dcc8a3e6826b49f7d0169',
    messagingSenderId: '743465184716',
    projectId: 'noderedfirebase-769cf',
    databaseURL: 'https://noderedfirebase-769cf-default-rtdb.firebaseio.com',
    storageBucket: 'noderedfirebase-769cf.appspot.com',
    iosBundleId: 'com.example.bleMesh',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDLLC1a4Nm9bNGIuAypmcgQvmmBEZIYFuw',
    appId: '1:743465184716:web:76510c0e853d202a7d0169',
    messagingSenderId: '743465184716',
    projectId: 'noderedfirebase-769cf',
    authDomain: 'noderedfirebase-769cf.firebaseapp.com',
    databaseURL: 'https://noderedfirebase-769cf-default-rtdb.firebaseio.com',
    storageBucket: 'noderedfirebase-769cf.appspot.com',
    measurementId: 'G-FHLDM9RP78',
  );
}
