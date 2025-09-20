// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'player_tabs_screen.dart';
import 'manager_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // V-- THIS IS THE UPDATED ERROR HANDLING LOGIC --V
              if (userSnapshot.hasError || !userSnapshot.data!.exists) {
                // If there's an error or the user document doesn't exist,
                // show a dedicated error screen with a logout button.
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('An error occurred or user data not found.'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Return to Login'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // ^-- END OF UPDATED LOGIC --^

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'player';

              if (role == 'manager') {
                return const ManagerScreen();
              } else {
                return const PlayerTabsScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}