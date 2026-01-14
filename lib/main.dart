import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/dashboard_page.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Optional: for cleaner URLs

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  // DISABLE PERSISTENCE FOR WEB TO PREVENT HANGS
  try {
    // Initialize Firebase
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      // Si ya existe la app, continuamos sin error
      if (e.toString().contains('duplicate-app')) {
        debugPrint('Firebase ya estaba inicializado.');
      } else {
        rethrow;
      }
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    // Ignore error
  }
  // usePathUrlStrategy(); // Optional
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigitalZone Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0f172a), // Slate 900
        primaryColor: const Color(0xFF6366f1), // Indigo 500
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e293b), // Slate 800
          elevation: 0,
        ),
        cardColor: const Color(0xFF1e293b),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366f1),
          secondary: Color(0xFFec4899), // Pink 500
          surface: Color(0xFF1e293b),
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}
