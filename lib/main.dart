// lib/main.dart (Final for this step)

import 'package:flutter/material.dart';
import 'screens/venue_list_screen.dart'; // <-- ADD THIS IMPORT

void main() {
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
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VenueListScreen(), // <-- CHANGE THIS LINE
    );
  }
}