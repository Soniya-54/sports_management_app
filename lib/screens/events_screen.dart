// lib/screens/events_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('eventDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No upcoming events found.'));
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final eventDoc = events[index];
              final eventData = eventDoc.data() as Map<String, dynamic>;
              final eventDate = (eventData['eventDate'] as Timestamp).toDate();
              final formattedDate = DateFormat.yMMMd().format(eventDate);

              // Create an Event object from the Firestore data
              final event = Event(
                id: eventDoc.id,
                name: eventData['name'] ?? 'No Name',
                description: eventData['description'] ?? 'No Description',
                imageUrl: eventData['imageUrl'] ?? '',
                venueName: eventData['venueName'] ?? 'No Venue',
                eventDate: eventData['eventDate'] ?? Timestamp.now(),
                entryFee: (eventData['entryFee'] as num?)?.toDouble() ?? 0.0,
              );

              return Card(
                margin: const EdgeInsets.all(12.0),
                clipBehavior: Clip.antiAlias,
                elevation: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.network(
                      event.imageUrl,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 180,
                          child: Icon(Icons.emoji_events, size: 80, color: Colors.grey),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            '$formattedDate at ${event.venueName}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      // V-- UPDATE THE ONPRESSED FUNCTION --V
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the detail screen, passing the Event object
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        child: const Text('View Details & Register'),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}