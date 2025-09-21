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

  final _venueNameController = TextEditingController();
  final _sportTypeController = TextEditingController(text: 'Futsal');
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

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
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
    if (user == null) return;

    setState(() { _isLoading = true; });

    try {
      // V-- NEW: DOUBLE BOOKING VALIDATION LOGIC --V
      final formattedTime = _selectedTime!.format(context);
      final startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final endOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);

      // We need to find the venueId first based on the name.
      // This is a simplification. A real app would use a dropdown to select a venue.
      final venueQuery = await FirebaseFirestore.instance
          .collection('venues')
          .where('name', isEqualTo: _venueNameController.text.trim())
          .limit(1)
          .get();
      
      if (venueQuery.docs.isEmpty) {
        throw Exception('Venue not found. Please check the name and try again.');
      }
      final venueId = venueQuery.docs.first.id;

      // Now check if a booking already exists for this venue, date, and time.
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('venueId', isEqualTo: venueId)
          .where('bookingDate', isGreaterThanOrEqualTo: startOfDay)
          .where('bookingDate', isLessThanOrEqualTo: endOfDay)
          .where('timeSlot', isEqualTo: formattedTime)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        // If we find any documents, it means the slot is already booked.
        throw Exception('This time slot is already booked for the selected venue and date.');
      }
      // ^-- END OF VALIDATION LOGIC --^


      // If validation passes, proceed to create the post.
      await FirebaseFirestore.instance.collection('team_posts').add({
        'venueName': _venueNameController.text.trim(),
        'venueId': venueId,
        'sportType': _sportTypeController.text.trim(),
        'gameDate': Timestamp.fromDate(_selectedDate!),
        'gameTime': formattedTime,
        'playersNeeded': int.tryParse(_playersNeededController.text.trim()) ?? 1,
        'postedByUserId': user.uid,
        'postedByUserEmail': user.email,
        'createdAt': Timestamp.now(),
        'joinedPlayerIds': [],
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${e.toString()}'), backgroundColor: Colors.red),
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
                      decoration: const InputDecoration(labelText: 'Venue Name', hintText: 'Enter the exact venue name'),
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