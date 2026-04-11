import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // You will add iOS/Web configs here later, for now we target Android
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNhmpzFQKV9UkA4fYYLnfzeI8Mx20qWF0', // Find this in Firebase Console Settings
    appId: '1:693008491248:android:afbcbff115052e421a5835',   // Find this in Firebase Console Settings
    messagingSenderId: '693008491248',
    projectId: 'unwaver-67be8',
    storageBucket: 'unwaver-67be8.appspot.com',
  );
}