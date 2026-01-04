import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// IMPORT YOUR NEW HOME SCREEN
import 'Screens/Home/home_screen.dart'; 
// import 'Screens/Accounts/login_screen.dart'; // Keep this if you want to start at login

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase Error: $e");
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
        primaryColor: const Color.fromARGB(255, 29, 140, 160),
        useMaterial3: true,
      ),
      // --- THE CRITICAL FIX ---
      // Point this DIRECTLY to HomeScreen. 
      // Do NOT point it to "MainLayout" or "BaseScreen".
      home: const HomeScreen(), 
    );
  }
}