import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // New Import
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New Import

import 'firebase_options.dart';
import 'services/app_data_service.dart';
import 'screens/main_layout.dart';
import 'screens/onboarding/onboarding_screen.dart';

// Ensure these exist or create placeholders for them
import 'screens/accounts/register_screen.dart'; 
import 'screens/accounts/login_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables
  await dotenv.load(fileName: ".env");

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Check "Onboarding Seen" Flag
  // We load this BEFORE the app starts to prevent screen flickering
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(UnwaverApp(seenOnboarding: seenOnboarding));
}

class UnwaverApp extends StatelessWidget {
  final bool seenOnboarding;

  // Pass the flag into the app
  const UnwaverApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppDataService>(
          create: (_) => AppDataService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Unwaver',
        
        // --- GLOBAL THEME ---
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1D8CA0),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        
        // --- THE GATEKEEPER ---
        // Instead of hardcoding a screen, we use the AuthGate to decide
        home: AuthGate(seenOnboarding: seenOnboarding),
        
        // Define routes if you need to navigate by name later
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainLayout(),
        },
      ),
    );
  }
}

// --- NEW WIDGET: THE AUTH GATE ---
class AuthGate extends StatelessWidget {
  final bool seenOnboarding;

  const AuthGate({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    // 1. If user has NOT seen onboarding, show it immediately.
    if (!seenOnboarding) {
      return const OnboardingScreen();
    }

    // 2. If user HAS seen onboarding, check if they are logged in.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to check credentials...
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(
             body: Center(child: CircularProgressIndicator()),
           );
        }

        // Case A: User is Logged In -> Go to App
        if (snapshot.hasData) {
          return const MainLayout();
        }
        
        // Case B: User is Not Logged In -> Go to Login
        // (Since they have already seen onboarding, they are a "returning" user flow)
        return const LoginScreen(); 
      },
    );
  }
}