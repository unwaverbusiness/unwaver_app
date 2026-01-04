import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Import your screen files here
import 'Screens/Accounts/login_screen.dart';
import 'Screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with safety check
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase already initialized or error: $e");
  }

  runApp(const UnwaverApp());
}

class UnwaverApp extends StatelessWidget {
  const UnwaverApp({super.key});

  // DEVELOPMENT TOGGLE: Set to 'true' to skip login and stay on Home/Navbar.
  // Set to 'false' to use real Firebase session logic.
  static const bool devBypassLogin = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unwaver',
      theme: ThemeData(
        // Your brand color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 29, 140, 160),
          primary: const Color.fromARGB(255, 29, 140, 160),
        ),
        useMaterial3: true,
      ),
      // If devBypassLogin is true, it goes straight to MainLayout.
      // Otherwise, it listens to the Firebase Auth Stream.
      home: devBypassLogin ? const MainLayout() : const AuthGate(),
    );
  }
}

/// The AuthGate listens to the user's login state in real-time.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If the connection is still waiting, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If the snapshot has user data, the user is logged in
        if (snapshot.hasData) {
          return const MainLayout();
        }

        // 3. Otherwise, the user is logged out, show the Login screen
        return const LoginScreen();
      },
    );
  }
}