// lib/screens/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/venue_model.dart';
import 'search_selection_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;

  final _sportTypeController = TextEditingController(text: 'Futsal');
  final _playersNeededController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Venue? _selectedVenue;
  List<Venue> _allVenues = [];

  @override
  void initState() {
    super.initState();
    _fetchAllVenues();
  }

  @override
  void dispose() {
    _sportTypeController.dispose();
    _playersNeededController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllVenues() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('venues').get();
    final venues = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Venue(
        id: doc.id,
        name: data['name'] ?? '', location: data['location'] ?? '',
        sportType: data['sportType'] ?? '',
        pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['imageUrl'] ?? '', description: data['description'] ?? '',
        openingTime: data['openingTime'] ?? '', closingTime: data['closingTime'] ?? '',
        slotDuration: (data['slotDuration'] as num?)?.toInt() ?? 0,
      );
    }).toList();
    setState(() {
      _allVenues = venues;
    });
  }

  Future<void> _selectVenue() async {
    final result = await Navigator.of(context).push<Venue>(
      MaterialPageRoute(
        builder: (context) => SearchSelectionScreen(allVenues: _allVenues),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedVenue = result;
      });
    }
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate ?? now, firstDate: now, lastDate: now.add(const Duration(days: 30)));
    if (pickedDate != null) { setState(() { _selectedDate = pickedDate; }); }
  }

  Future<void> _presentTimePicker() async {
    final pickedTime = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (pickedTime != null) { setState(() { _selectedTime = pickedTime; }); }
  }

  Future<void> _submitPost() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null || _selectedTime == null || _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields, including venue, date and time.'), backgroundColor: Colors.red));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _isLoading = true; });

    try {
      final formattedTime = _selectedTime!.format(context);
      final gameDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      final bookingSnapshot = await FirebaseFirestore.instance.collection('bookings').where('venueId', isEqualTo: _selectedVenue!.id).where('bookingDate', isEqualTo: Timestamp.fromDate(gameDateTime)).limit(1).get();
      if (bookingSnapshot.docs.isNotEmpty) {
        throw Exception('This exact date and time slot is already booked for this venue.');
      }
      await FirebaseFirestore.instance.collection('team_posts').add({
        'venueName': _selectedVenue!.name, 'venueId': _selectedVenue!.id, 'sportType': _sportTypeController.text.trim(),
        'gameDate': Timestamp.fromDate(gameDateTime), 'gameTime': formattedTime,
        'playersNeeded': int.tryParse(_playersNeededController.text.trim()) ?? 1,
        'postedByUserId': user.uid, 'postedByUserEmail': user.email, 'createdAt': Timestamp.now(), 'joinedPlayerIds': [],
      });
      if (mounted) { Navigator.of(context).pop(); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create post: ${e.toString()}'), backgroundColor: Colors.red));
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
        actions: [ IconButton(onPressed: _isLoading ? null : _submitPost, icon: const Icon(Icons.save)) ],
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
                      key: ValueKey(_selectedVenue?.id ?? 'no-venue'),
                      initialValue: _selectedVenue != null ? '${_selectedVenue!.name} (${_selectedVenue!.location})' : '',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Venue', hintText: 'Tap to select a venue',
                        border: OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      onTap: _selectVenue,
                      validator: (_) => _selectedVenue == null ? 'Please select a venue.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sportTypeController,
                      decoration: const InputDecoration(labelText: 'Sport Type', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a sport type.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _playersNeededController,
                      decoration: const InputDecoration(labelText: 'Number of Players Needed', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || int.tryParse(value.trim()) == null) ? 'Please enter a valid number.' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Text(_selectedDate == null ? 'No date chosen' : 'Date: ${DateFormat.yMd().format(_selectedDate!)}')),
                        TextButton(onPressed: _presentDatePicker, child: const Text('Choose Date')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text(_selectedTime == null ? 'No time chosen' : 'Time: ${_selectedTime!.format(context)}')),
                        TextButton(onPressed: _presentTimePicker, child: const Text('Choose Time')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}