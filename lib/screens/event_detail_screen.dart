// lib/screens/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart'; // We need to create this model

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isRegistered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfRegistered();
  }

  // Check if the current user is already in the registrations sub-collection for this event
  Future<void> _checkIfRegistered() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }
    try {
      final registrationDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .doc(user.uid)
          .get();
      
      if (mounted) {
        setState(() {
          _isRegistered = registrationDoc.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      print("Error checking registration status: $e");
    }
  }

  Future<void> _registerForEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to register.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Create a document in the 'registrations' sub-collection with the user's ID
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .doc(user.uid)
          .set({
            'userEmail': user.email,
            'registrationDate': Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully registered for the event!'), backgroundColor: Colors.green));
        setState(() { _isRegistered = true; });
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
       if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().add_jm().format(widget.event.eventDate.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              widget.event.imageUrl,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 250, child: Icon(Icons.emoji_events, size: 100, color: Colors.grey));
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.event.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  InfoRow(icon: Icons.calendar_today, text: formattedDate),
                  const SizedBox(height: 8),
                  InfoRow(icon: Icons.location_on, text: widget.event.venueName),
                  const SizedBox(height: 8),
                  InfoRow(icon: Icons.money, text: 'Entry Fee: Rs. ${widget.event.entryFee.toStringAsFixed(0)}'),
                  const Divider(height: 32),
                  const Text('About this Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.event.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _isRegistered ? null : _registerForEvent, // Disable button if already registered
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_isRegistered ? 'Registered' : 'Register Now'),
            ),
      ),
    );
  }
}

// A small helper widget to keep the UI clean
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}