import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'services/app_data_service.dart'; // Lowercase folder
// ignore: unused_import
import 'screens/main_layout.dart';      // Lowercase folder

// FIX: Package name is 'unwaver_app' + lowercase path
import 'package:unwaver/screens/onboarding/onboarding_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file before running the app
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const UnwaverApp());
}

class UnwaverApp extends StatelessWidget {
  const UnwaverApp({super.key});

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
        
        // --- GLOBAL THEME UPDATES ---
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1D8CA0), // Your Teal Seed
          
          // 1. Force the AppBar to be Black with White Text
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
          
          // 2. Scaffold background
          scaffoldBackgroundColor: Colors.white,
        ),
        
        // Set Onboarding as the initial screen
        home: const OnboardingScreen(),
      ),
    );
  }
}