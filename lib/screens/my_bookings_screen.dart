// lib/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // A safety check in case this screen is somehow accessed by a logged-out user
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your bookings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        // We don't need a logout button here as it's on the other screen
      ),
      body: StreamBuilder<QuerySnapshot>(
        // This is the core query: get documents from the 'bookings' collection
        // WHERE the 'userId' field matches the ID of the currently logged-in user.
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true) // Show newest bookings first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no bookings yet.'));
          }

          final bookingDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookingDocs.length,
            itemBuilder: (context, index) {
              final bookingData = bookingDocs[index].data() as Map<String, dynamic>;
              
              // Formatting the date to be more readable
              final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();
              final formattedDate = "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  leading: const Icon(Icons.sports),
                  title: Text(
                    bookingData['venueName'] ?? 'No Venue Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('On $formattedDate at ${bookingData['timeSlot']}'),
                  trailing: Text(
                    'Rs. ${bookingData['totalPrice']}',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
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