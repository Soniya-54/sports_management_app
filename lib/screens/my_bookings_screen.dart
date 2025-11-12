// lib/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/empty_state_widget.dart'; // <-- 1. IMPORT THE NEW WIDGET

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your bookings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // V-- 2. REPLACE THE OLD WIDGET WITH THE NEW ONE --V
            return const EmptyStateWidget(
              icon: Icons.calendar_today_outlined,
              title: 'No Bookings Yet',
              message: 'When you book a venue, your upcoming and past bookings will appear here.',
            );
          }

          final bookingDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookingDocs.length,
            itemBuilder: (context, index) {
              final bookingData = bookingDocs[index].data() as Map<String, dynamic>;
              
              final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();
              final formattedDate = "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  leading: Icon(
                    bookingData['bookingStatus'] == 'completed' ? Icons.check_circle : Icons.sports,
                    color: bookingData['bookingStatus'] == 'completed' ? Colors.green : Theme.of(context).primaryColor,
                  ),
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