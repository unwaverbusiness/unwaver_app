import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/app_data_service.dart';
import 'Screens/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (fail fast if misconfigured)
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
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1D8CA0),
        ),
        home: const MainLayout(),
      ),
    );
  }
}
