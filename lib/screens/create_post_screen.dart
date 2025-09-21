// lib/screens/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;

  // Form field controllers
  final _venueNameController = TextEditingController();
  final _sportTypeController = TextEditingController(text: 'Futsal'); // Default value
  final _playersNeededController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _venueNameController.dispose();
    _sportTypeController.dispose();
    _playersNeededController.dispose();
    super.dispose();
  }

  // Function to show the date picker
  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)), // Can post for games up to 30 days in advance
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  // Function to show the time picker
  Future<void> _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    setState(() {
      _selectedTime = pickedTime;
    });
  }

  Future<void> _submitPost() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields, including date and time.'), backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Safety check

    setState(() { _isLoading = true; });

    try {
      // We will create a dummy venueId for now. In a real app, you'd select from a list.
      final venueId = FirebaseFirestore.instance.collection('venues').doc().id;

      await FirebaseFirestore.instance.collection('team_posts').add({
        'venueName': _venueNameController.text.trim(),
        'venueId': venueId,
        'sportType': _sportTypeController.text.trim(),
        'gameDate': Timestamp.fromDate(_selectedDate!),
        'gameTime': _selectedTime!.format(context),
        'playersNeeded': int.tryParse(_playersNeededController.text.trim()) ?? 1,
        'postedByUserId': user.uid,
        'postedByUserEmail': user.email,
        'createdAt': Timestamp.now(),
        'joinedPlayerIds': [], // Initialize with an empty list of joined players
      });

      if (mounted) {
        Navigator.of(context).pop(); // Go back after successful post
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Post'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _submitPost,
            icon: const Icon(Icons.save),
            tooltip: 'Submit Post',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _venueNameController,
                      decoration: const InputDecoration(labelText: 'Venue Name'),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a venue name.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sportTypeController,
                      decoration: const InputDecoration(labelText: 'Sport Type'),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a sport type.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _playersNeededController,
                      decoration: const InputDecoration(labelText: 'Number of Players Needed'),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || int.tryParse(value.trim()) == null) ? 'Please enter a valid number.' : null,
                    ),
                    const SizedBox(height: 24),
                    // Date and Time Pickers
                    Row(
                      children: [
                        Expanded(
                          child: Text(_selectedDate == null ? 'No date chosen' : 'Date: ${DateFormat.yMd().format(_selectedDate!)}'),
                        ),
                        TextButton(
                          onPressed: _presentDatePicker,
                          child: const Text('Choose Date'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_selectedTime == null ? 'No time chosen' : 'Time: ${_selectedTime!.format(context)}'),
                        ),
                        TextButton(
                          onPressed: _presentTimePicker,
                          child: const Text('Choose Time'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}