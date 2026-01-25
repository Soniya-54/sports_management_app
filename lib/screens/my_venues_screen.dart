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
            return const Center(
              child: Text('Something went wrong! Check the debug console.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You have not added any venues yet. Tap the + button to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
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
                name: venueData['name'] ?? '',
                location: venueData['location'] ?? '',
                sportType: venueData['sportType'] ?? '',
                pricePerHour:
                    (venueData['pricePerHour'] as num?)?.toDouble() ?? 0.0,
                imageUrl: venueData['imageUrl'] ?? '',
                description: venueData['description'] ?? '',
                openingTime: venueData['openingTime'] ?? '09:00',
                closingTime: venueData['closingTime'] ?? '21:00',
                slotDuration:
                    (venueData['slotDuration'] as num?)?.toInt() ?? 60,
              );

              return VenueBookingInfo(venue: venue);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  const AddEditVenueScreen(formMode: FormMode.add),
            ),
          );
        },
        tooltip: 'Add New Venue',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class VenueBookingInfo extends StatelessWidget {
  final Venue venue;

  const VenueBookingInfo({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('venueId', isEqualTo: venue.id)
            .where('bookingDate', isGreaterThanOrEqualTo: startOfToday)
            .where('bookingDate', isLessThan: endOfToday)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(title: Text('Loading...'));
          }
          final bookingCount = snapshot.data?.docs.length ?? 0;

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ManagerBookingScreen(venue: venue),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          venue.location,
                          style: TextStyle(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Chip(
                    label: Text('$bookingCount Bookings'),
                    backgroundColor: Colors.green.shade100,
                    labelStyle: TextStyle(color: Colors.green.shade900),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Venue',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddEditVenueScreen(
                            formMode: FormMode.edit,
                            venue: venue,
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
      ),
    );
  }
}
