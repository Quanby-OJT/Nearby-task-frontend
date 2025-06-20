// File generated by FlutterFire CLI.
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
    apiKey: 'AIzaSyB3e3985ENLX--RiNew5S-hbQRJwPBww7Y',
    appId: '1:150912847034:web:c4a6c24657b5501669c683',
    messagingSenderId: '150912847034',
    projectId: 'qtask-c6ec9',
    authDomain: 'qtask-c6ec9.firebaseapp.com',
    storageBucket: 'qtask-c6ec9.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOLMNSlkYAhfg3b5hiGqz7Ca9z8vHmEoI',
    appId: '1:150912847034:android:45582c4063ebfac269c683',
    messagingSenderId: '150912847034',
    projectId: 'qtask-c6ec9',
    storageBucket: 'qtask-c6ec9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUOd6UcxJNV6SRJYtYCTBASnwmaKBbuww',
    appId: '1:150912847034:ios:89147a3ca33c227f69c683',
    messagingSenderId: '150912847034',
    projectId: 'qtask-c6ec9',
    storageBucket: 'qtask-c6ec9.firebasestorage.app',
    iosBundleId: 'com.example.flutterFe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAUOd6UcxJNV6SRJYtYCTBASnwmaKBbuww',
    appId: '1:150912847034:ios:89147a3ca33c227f69c683',
    messagingSenderId: '150912847034',
    projectId: 'qtask-c6ec9',
    storageBucket: 'qtask-c6ec9.firebasestorage.app',
    iosBundleId: 'com.example.flutterFe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB3e3985ENLX--RiNew5S-hbQRJwPBww7Y',
    appId: '1:150912847034:web:0abc72cf7451b00c69c683',
    messagingSenderId: '150912847034',
    projectId: 'qtask-c6ec9',
    authDomain: 'qtask-c6ec9.firebaseapp.com',
    storageBucket: 'qtask-c6ec9.firebasestorage.app',
  );
}
