// lib/screens/my_venues_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue_model.dart';
import 'add_edit_venue_screen.dart';
import 'manager_booking_screen.dart';

class MyVenuesScreen extends StatelessWidget {
  const MyVenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You are not logged in.')),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('venues')
            .where('managerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong! Check the debug console.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('You have not added any venues yet. Tap the + button to get started!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
              ),
            );
          }

          final venueDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: venueDocs.length,
            itemBuilder: (context, index) {
              final venueDoc = venueDocs[index];
              final venueData = venueDoc.data() as Map<String, dynamic>;
              
              final venue = Venue(
                  id: venueDoc.id,
                  name: venueData['name'] ?? '', location: venueData['location'] ?? '',
                  sportType: venueData['sportType'] ?? '',
                  pricePerHour: (venueData['pricePerHour'] as num?)?.toDouble() ?? 0.0,
                  imageUrl: venueData['imageUrl'] ?? '', description: venueData['description'] ?? '',
                  openingTime: venueData['openingTime'] ?? '09:00',
                  closingTime: venueData['closingTime'] ?? '21:00',
                  slotDuration: (venueData['slotDuration'] as num?)?.toInt() ?? 60,
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(venue.location),
                  // V-- 2. THIS IS THE UPDATED TRAILING SECTION --V
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Prevents the Row from taking too much space
                    children: [
                      // Button to manage bookings
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        tooltip: 'Manage Bookings',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ManagerBookingScreen(venue: venue),
                            ),
                          );
                        },
                      ),
                      // Button to edit venue details
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Venue',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditVenueScreen(
                                formMode: FormMode.edit, venue: venue,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditVenueScreen(formMode: FormMode.add),
            ),
          );
        },
        tooltip: 'Add New Venue',
        child: const Icon(Icons.add),
      ),
    );
  }
}