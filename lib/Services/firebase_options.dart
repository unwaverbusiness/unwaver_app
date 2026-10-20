import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNhmpzFQKV9UkA4fYYLnfzeI8Mx20qWF0',
    appId: '1:693008491248:web:a743f48fde8906841a5835',
    messagingSenderId: '693008491248',
    projectId: 'unwaver-67be8',
    authDomain: 'unwaver-67be8.firebaseapp.com',
    storageBucket: 'unwaver-67be8.firebasestorage.app',
    measurementId: 'G-MEXPKZ6MVW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNhmpzFQKV9UkA4fYYLnfzeI8Mx20qWF0', // Find this in Firebase Console Settings
    appId: '1:693008491248:android:afbcbff115052e421a5835',   // Find this in Firebase Console Settings
    messagingSenderId: '693008491248',
    projectId: 'unwaver-67be8',
    authDomain: 'unwaver-67be8.firebaseapp.com',
    storageBucket: 'unwaver-67be8.firebasestorage.app',
  );
}