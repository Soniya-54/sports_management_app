// lib/screens/manager_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_venues_screen.dart'; // Import the new screen

class ManagerScreen extends StatelessWidget {
  const ManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, the ManagerScreen's body will just be the MyVenuesScreen.
    // Later, we can turn this into a TabsScreen for managers if needed.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          )
        ],
      ),
      body: const MyVenuesScreen(), // Show the list of their venues
    );
  }
}