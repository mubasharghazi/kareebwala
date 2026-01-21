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
    apiKey: 'AIzaSyBs3pk7zlyQI7BZi5J24jcXfPVBepy2EcY',
    appId: '1:892210957819:web:a8cdeca7739948a279cf5e',
    messagingSenderId: '892210957819',
    projectId: 'daywise-5487l',
    authDomain: 'daywise-5487l.firebaseapp.com',
    storageBucket: 'daywise-5487l.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBArL7aO5NX0QZ0cWjxrqFvEn7BkRzFbZk',
    appId: '1:892210957819:android:04d737f21203bcb179cf5e',
    messagingSenderId: '892210957819',
    projectId: 'daywise-5487l',
    storageBucket: 'daywise-5487l.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAy077E3wISuTin76SQri9DQ8WPsVH-VoI',
    appId: '1:892210957819:ios:a4e1aa263763809c79cf5e',
    messagingSenderId: '892210957819',
    projectId: 'daywise-5487l',
    storageBucket: 'daywise-5487l.firebasestorage.app',
    iosBundleId: 'com.example.kareebwala',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAy077E3wISuTin76SQri9DQ8WPsVH-VoI',
    appId: '1:892210957819:ios:a4e1aa263763809c79cf5e',
    messagingSenderId: '892210957819',
    projectId: 'daywise-5487l',
    storageBucket: 'daywise-5487l.firebasestorage.app',
    iosBundleId: 'com.example.kareebwala',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBs3pk7zlyQI7BZi5J24jcXfPVBepy2EcY',
    appId: '1:892210957819:web:d0217ccf62af22f679cf5e',
    messagingSenderId: '892210957819',
    projectId: 'daywise-5487l',
    authDomain: 'daywise-5487l.firebaseapp.com',
    storageBucket: 'daywise-5487l.firebasestorage.app',
  );
}
