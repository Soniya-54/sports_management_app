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
            // This is the updated mapping logic
            return Venue(
              id: doc.id,
              name: data['name'] ?? 'No Name',
              location: data['location'] ?? 'No Location',
              sportType: data['sportType'] ?? 'No Sport Type',
              pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
              imageUrl: data['imageUrl'] ?? '',
              description: data['description'] ?? 'No description available.',
              
              // NEW: Read the dynamic time slot fields from Firestore
              // Provide sensible defaults in case the data is missing.
              openingTime: data['openingTime'] ?? '09:00',
              closingTime: data['closingTime'] ?? '21:00',
              slotDuration: (data['slotDuration'] as num?)?.toInt() ?? 60,
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
                    leading: Hero(
                      tag: venue.id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          venue.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
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