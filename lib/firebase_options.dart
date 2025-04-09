
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
        throw UnsupportedError(
          'macOS is not supported for this app.',
        );
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBJ6H5JV1EG_YVfBI1TWNspQDcJF-1NaM0",
    authDomain: "armadillo-45bef.firebaseapp.com",
    projectId: "armadillo-45bef",
    storageBucket: "armadillo-45bef.appspot.com",
    messagingSenderId: "963656261848",
    appId: "1:963656261848:web:f5cfa851af38e2f2a2e0aa",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJ6H5JV1EG_YVfBI1TWNspQDcJF-1NaM0',
    appId: '1:963656261848:android:67e8e3daed26a9b6a2e0aa',
    messagingSenderId: '963656261848',
    projectId: 'armadillo-45bef',  
    storageBucket: 'armadillo-45bef.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBJ6H5JV1EG_YVfBI1TWNspQDcJF-1NaM0",
    appId: "1:963656261848:ios:7a8cc7e3d5a09d16a2e0aa",
    messagingSenderId: "963656261848",
    projectId: "armadillo-45bef",
    storageBucket: "armadillo-45bef.appspot.com",
    iosBundleId: "com.example.crud",
  );
  
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBJ6H5JV1EG_YVfBI1TWNspQDcJF-1NaM0',
    appId: '1:963656261848:windows:67e8e3daed26a9b6a2e0aa',
    messagingSenderId: '963656261848',
    projectId: 'armadillo-45bef',  
    storageBucket: 'armadillo-45bef.appspot.com',
  );
}