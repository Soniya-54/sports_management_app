// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Make sure you have this import
import 'firebase_options.dart';                   // Make sure you have this import
import 'screens/auth_gate.dart';              

// The main entry point of the application
Future<void> main() async {
  // This line is essential to ensure that native code bindings are initialized
  // before any async operations, like Firebase initialization.
  WidgetsFlutterBinding.ensureInitialized();
  
  // This line connects your app to your Firebase project using the
  // configuration from firebase_options.dart. It must be awaited.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Only after Firebase is initialized, run the app.
  runApp(const SportsManagementApp());
}

class SportsManagementApp extends StatelessWidget {
  const SportsManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sports Management App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', // Your custom font
        // Use provided green (#80b918) as the seed color so the Material
        // color scheme derives primary/secondary/containers from it.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF80B918)),
        // Button theming: make buttons use the primary green with white text
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF80B918),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF80B918),
            // Match vertical padding increase for consistency
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF80B918),
            side: const BorderSide(color: Color(0xFF80B918)),
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          ),
        ),
        // You can keep any other theme customizations here
      ),
      // The first screen the user sees is the LoginScreen
      home: const AuthGate(),
    );
  }
}