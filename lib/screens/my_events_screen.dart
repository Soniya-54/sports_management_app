// lib/screens/my_events_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'add_edit_event_screen.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('You are not logged in.')));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('managerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have not created any events yet.'));
          }

          final eventDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: eventDocs.length,
            itemBuilder: (context, index) {
              final eventDoc = eventDocs[index];
              final eventData = eventDoc.data() as Map<String, dynamic>;
              
              final event = Event(
                id: eventDoc.id,
                name: eventData['name'] ?? '',
                description: eventData['description'] ?? '',
                imageUrl: eventData['imageUrl'] ?? '',
                venueName: eventData['venueName'] ?? '',
                eventDate: eventData['eventDate'] ?? Timestamp.now(),
                entryFee: (eventData['entryFee'] as num?)?.toDouble() ?? 0.0,
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(event.venueName),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEditEventScreen(
                          formMode: EventFormMode.edit,
                          event: event,
                        ),
                      ),
                    );
                  },
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
              builder: (context) => const AddEditEventScreen(formMode: EventFormMode.add),
            ),
          );
        },
        tooltip: 'Add New Event',
        child: const Icon(Icons.add),
      ),
    );
  }
}