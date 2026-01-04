import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Screens/Accounts/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: This check prevents the "Duplicate App" crash during Hot Restarts
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const UnwaverApp());
}

class UnwaverApp extends StatelessWidget {
  const UnwaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unwaver',
      theme: ThemeData(
        // I kept your custom teal color here
        primaryColor: const Color.fromARGB(255, 29, 140, 160),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}