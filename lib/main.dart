import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_data_service.dart';
import 'Screens/main_layout.dart';  // CHANGE THIS LINE

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
    return ChangeNotifierProvider(
      create: (context) => AppDataService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Unwaver',
        theme: ThemeData(
          primaryColor: const Color.fromARGB(255, 29, 140, 160),
          useMaterial3: true,
        ),
        home: const MainLayout(),  // CHANGE THIS LINE
      ),
    );
  }
}