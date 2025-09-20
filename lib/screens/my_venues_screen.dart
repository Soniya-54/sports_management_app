// lib/screens/my_venues_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue_model.dart';
// We will create the add/edit screen in the next step
// import 'add_edit_venue_screen.dart';

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
      appBar: AppBar(
        title: const Text('My Venues'),
        // The logout button will be on the manager's main tabs screen, not here.
      ),
      // This is the query to get ONLY the venues created by the current manager.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('venues')
            .where('managerId', isEqualTo: user.uid) // The key filtering logic
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // It's very likely the error is a missing index. The link will be in the debug console.
            return const Center(child: Text('Something went wrong! Check the debug console for an index link.'));
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
              final venueData = venueDocs[index].data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Text(
                    venueData['name'] ?? 'No Venue Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(venueData['location'] ?? 'No Location'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    // TODO: Navigate to the edit screen, passing this venue's data.
                    print('Tapped on venue ID: ${venueDocs[index].id}');
                  },
                ),
              );
            },
          );
        },
      ),
      // This button will allow managers to add a new venue.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to the Add/Edit screen in "add" mode.
          print('Add new venue button pressed!');
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Venue',
      ),
    );
  }
}