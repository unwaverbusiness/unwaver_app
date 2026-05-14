import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unwaver/screens/layout/main_layout.dart';
import 'package:unwaver/screens/settings/theme/theme_manager.dart';

import 'services/firebase_options.dart';
import 'services/app_data_service.dart';

// Ensure these exist or create placeholders for them
import 'screens/login/register_screen.dart';
import 'screens/login/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(UnwaverApp(seenOnboarding: seenOnboarding));
}

class UnwaverApp extends StatelessWidget {
  final bool seenOnboarding;

  const UnwaverApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppDataService>(
          create: (_) => AppDataService(),
        ),
      ],
      child: ValueListenableBuilder<Color>(
          valueListenable: appThemeColor,
          builder: (context, themeColor, child) {
            return ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeMode,
                builder: (context, themeMode, child) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'Unwaver',
                    themeMode: themeMode,

                    // --- LIGHT MODE (White bg, Black components) ---
                    theme: ThemeData(
                      useMaterial3: true,
                      brightness: Brightness.light,
                      colorSchemeSeed: themeColor,
                      scaffoldBackgroundColor: Colors.white,
                      appBarTheme: const AppBarTheme(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        centerTitle: true,
                        elevation: 0,
                      ),
                      drawerTheme: const DrawerThemeData(
                        backgroundColor: Colors.black,
                      ),
                      navigationBarTheme: NavigationBarThemeData(
                        backgroundColor: Colors.black,
                        indicatorColor: themeColor.withValues(
                            alpha: 0.3), // Accent highlight
                        iconTheme: WidgetStateProperty.all(
                            const IconThemeData(color: Colors.white)),
                        labelTextStyle: WidgetStateProperty.all(const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                      ),
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    // --- DARK MODE (Dark Grey bg, White components) ---
                    darkTheme: ThemeData(
                      useMaterial3: true,
                      brightness: Brightness.dark,
                      colorSchemeSeed: themeColor,
                      scaffoldBackgroundColor: Colors.grey.shade900,
                      appBarTheme: AppBarTheme(
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        centerTitle: true,
                        elevation: 0,
                      ),
                      drawerTheme: const DrawerThemeData(
                        backgroundColor: Colors.white,
                      ),
                      navigationBarTheme: NavigationBarThemeData(
                        backgroundColor: Colors.white,
                        indicatorColor: themeColor.withValues(
                            alpha: 0.3), // Accent highlight
                        iconTheme: WidgetStateProperty.all(
                            const IconThemeData(color: Colors.black)),
                        labelTextStyle: WidgetStateProperty.all(const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                      ),
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),

                    home: AuthGate(seenOnboarding: seenOnboarding),
                    routes: {
                      '/login': (context) => const LoginScreen(),
                      '/register': (context) => const RegisterScreen(),
                      '/home': (context) => const MainLayout(),
                    },
                  );
                });
          }),
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool seenOnboarding;

  const AuthGate({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainLayout();
        }
        return const LoginScreen();
      },
    );
  }
}
