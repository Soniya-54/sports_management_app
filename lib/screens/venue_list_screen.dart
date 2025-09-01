// lib/screens/venue_list_screen.dart

import 'package:flutter/material.dart';
import '../models/venue_model.dart'; // Import our Venue class

class VenueListScreen extends StatelessWidget {
  const VenueListScreen({super.key});

  // --- DUMMY DATA ---
  // This is a list of Venue objects. Later, this will come from Firebase.
  final List<Venue> dummyVenues = const [
    Venue(
      id: 'v1',
      name: 'Rhino Futsal',
      location: 'Kathmandu',
      sportType: 'Futsal',
      pricePerHour: 1500,
      imageUrl: 'https://via.placeholder.com/150', // A placeholder image URL
    ),
    Venue(
      id: 'v2',
      name: 'Dhuku Futsal Hub',
      location: 'Lalitpur',
      sportType: 'Futsal',
      pricePerHour: 1800,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Venue(
      id: 'v3',
      name: 'TU Cricket Ground',
      location: 'Kirtipur',
      sportType: 'Cricket',
      pricePerHour: 5000,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Venue(
      id: 'v4',
      name: 'Peace Badminton Hall',
      location: 'Pokhara',
      sportType: 'Badminton',
      pricePerHour: 800,
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];
  // --- END OF DUMMY DATA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is the orange bar at the top of the screen
      appBar: AppBar(
        title: const Text('Find a Venue'),
      ),
      // The body uses a ListView.builder to efficiently create a scrollable list
      body: ListView.builder(
        itemCount: dummyVenues.length, // Tell the list how many items to build
        itemBuilder: (ctx, index) {
          // This function builds one row of the list at a time
          final venue = dummyVenues[index];
          return Card( // The Card widget gives a nice shadow and border
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              // The content inside the card
              leading: Icon(Icons.sports_soccer, color: Theme.of(context).primaryColor),
              title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${venue.sportType} - ${venue.location}'),
              trailing: Text('Rs. ${venue.pricePerHour.toStringAsFixed(0)}/hr'),
            ),
          );
        },
      ),
    );
  }
}