// lib/screens/venue_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. IMPORT FIRESTORE
import '../models/venue_model.dart';
import 'venue_detail_screen.dart';

class VenueListScreen extends StatelessWidget {
  const VenueListScreen({super.key});

  // 2. The dummyVenues list has been DELETED.

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
      // 3. We wrap the body in a StreamBuilder.
      body: StreamBuilder<QuerySnapshot>(
        // This is the stream we are listening to. It gets all documents from the 'venues' collection.
        stream: FirebaseFirestore.instance.collection('venues').snapshots(),
        builder: (context, snapshot) {
          // 4. Handle the different states of the stream.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No venues found.'));
          }

          // 5. If we have data, we map the documents to a list of Venue objects.
          final loadedVenues = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Venue(
              id: doc.id,
              name: data['name'] ?? 'No Name',
              location: data['location'] ?? 'No Location',
              sportType: data['sportType'] ?? 'No Sport Type',
              pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
              imageUrl: data['imageUrl'] ?? '',
            );
          }).toList();

          // 6. We build the ListView using the data from Firestore.
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
                    leading: Icon(Icons.sports_soccer, color: Theme.of(context).primaryColor),
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