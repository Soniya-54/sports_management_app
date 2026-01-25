import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AllBookingsScreen extends StatelessWidget {
  const AllBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('You are not logged in.'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('venues')
            .where('managerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, venueSnapshot) {
          if (venueSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!venueSnapshot.hasData || venueSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no venues.'));
          }

          final venueIds = venueSnapshot.data!.docs
              .map((doc) => doc.id)
              .toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('venueId', whereIn: venueIds)
                .orderBy('bookingDate', descending: true)
                .snapshots(),
            builder: (context, bookingSnapshot) {
              if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!bookingSnapshot.hasData ||
                  bookingSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No bookings found for your venues.'),
                );
              }

              final bookings = bookingSnapshot.data!.docs;

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final data = booking.data() as Map<String, dynamic>;
                  final bookingDate = (data['bookingDate'] as Timestamp)
                      .toDate();
                  final formattedDate = DateFormat.yMMMd().format(bookingDate);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        '${data['venueName']} - ${data['timeSlot']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Booked by: ${data['userEmail']} on $formattedDate',
                      ),
                      trailing: Text(
                        'Rs. ${data['totalPrice']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
