import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:digitalzonehn/firebase_options.dart';
import 'package:digitalzonehn/screens/stats_view.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Disable persistence for web to avoid hanging
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    await initializeDateFormatting('es_ES', null);

    // Use pathUrlStrategy for clean URLs (if enabled in server)
    usePathUrlStrategy();

    runApp(const MyApp());
  } catch (e) {
    print("Initialization Error: $e");
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Error: $e"))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigitalZone Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'Outfit',
        useMaterial3: true,
      ),
      home: const StatsView(),
    );
  }
}
