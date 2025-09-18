// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'venue_list_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If the stream is still connecting to Firebase, show a loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          // The Scaffold must be returned directly without a semicolon inside the if block.
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // <-- The incorrect semicolon was here.
        }

        // 2. If the stream has data AND the user object is not null, they are logged in.
        if (snapshot.hasData && snapshot.data != null) {
          return const VenueListScreen(); // Show the main app
        }

        // 3. If the stream has no data, or the data is null, they are logged out.
        return const LoginScreen(); // Show the login screen
      },
    );
  }
}