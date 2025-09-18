// lib/screens/venue_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue_model.dart';
import 'venue_detail_screen.dart';

class VenueListScreen extends StatelessWidget {
  const VenueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Venue'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('venues').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No venues found.'));
          }

          final loadedVenues = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Venue(
              id: doc.id,
              name: data['name'] ?? 'No Name',
              location: data['location'] ?? 'No Location',
              sportType: data['sportType'] ?? 'No Sport Type',
              pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
              imageUrl: data['imageUrl'] ?? '',
              description: data['description'] ?? 'No description available.',
            );
          }).toList();

          return ListView.builder(
            itemCount: loadedVenues.length,
            itemBuilder: (ctx, index) {
              final venue = loadedVenues[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VenueDetailScreen(venue: venue),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    // V-- THIS IS THE UPDATED SECTION --V
                    leading: Hero(
                      // This tag MUST match the one on the detail screen
                      tag: venue.id,
                      child: ClipRRect( // Makes the image have rounded corners
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          venue.imageUrl,
                          width: 60,  // Set a fixed width for the list item image
                          height: 60, // Set a fixed height
                          fit: BoxFit.cover, // Ensures the image covers the space without distortion
                          // This errorBuilder is a fallback in case the image URL is bad or missing
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.sports_soccer,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            );
                          },
                        ),
                      ),
                    ),
                    // ^-- THIS IS THE END OF THE UPDATED SECTION --^
                    title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${venue.sportType} - ${venue.location}'),
                    trailing: Text('Rs. ${venue.pricePerHour.toStringAsFixed(0)}/hr'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}