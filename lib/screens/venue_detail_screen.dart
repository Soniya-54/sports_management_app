// lib/screens/venue_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/venue_model.dart';

class VenueDetailScreen extends StatelessWidget {
  // This screen will receive a 'Venue' object
  final Venue venue;

  // The constructor requires a 'venue' to be passed in
  const VenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The AppBar title will be the name of the specific venue
        title: Text(venue.name),
      ),
      body: Center(
        // For now, we just show a simple text message
        child: Text('Details for ${venue.name} will go here!'),
      ),
    );
  }
}