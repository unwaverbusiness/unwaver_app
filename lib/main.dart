import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'services/app_data_service.dart';
import 'Screens/main_layout.dart';

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
            backgroundColor: Colors.black, // Background color
            foregroundColor: Colors.white, // Text & Icon color
            centerTitle: true,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white), // Drawer/Back icons
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // 2. Optional: Ensure Scaffold background is white (or change to black if you want dark mode)
          scaffoldBackgroundColor: Colors.white,
        ),
        
        home: const MainLayout(),
      ),
    );
  }
}