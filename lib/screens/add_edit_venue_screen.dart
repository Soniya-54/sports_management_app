// lib/screens/add_edit_venue_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/venue_model.dart';

// This screen can be in one of two modes: adding a new venue, or editing an existing one.
enum FormMode { add, edit }

class AddEditVenueScreen extends StatefulWidget {
  final FormMode formMode;
  // The venue is optional. If we are editing, it will be passed in.
  // If we are adding, it will be null.
  final Venue? venue;

  const AddEditVenueScreen({
    super.key,
    required this.formMode,
    this.venue,
  });

  @override
  State<AddEditVenueScreen> createState() => _AddEditVenueScreenState();
}

class _AddEditVenueScreenState extends State<AddEditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;

  // Controllers for each text field
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;
  late TextEditingController _slotDurationController;
  String _selectedSportType = 'Futsal'; // Default sport type

  @override
  void initState() {
    super.initState();
    // If we are editing, initialize the controllers with the existing venue's data.
    // Otherwise, initialize them as empty.
    _nameController = TextEditingController(text: widget.venue?.name ?? '');
    _locationController = TextEditingController(text: widget.venue?.location ?? '');
    _priceController = TextEditingController(text: widget.venue?.pricePerHour.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.venue?.description ?? '');
    _imageUrlController = TextEditingController(text: widget.venue?.imageUrl ?? '');
    _openingTimeController = TextEditingController(text: widget.venue?.openingTime ?? '09:00');
    _closingTimeController = TextEditingController(text: widget.venue?.closingTime ?? '21:00');
    _slotDurationController = TextEditingController(text: widget.venue?.slotDuration.toString() ?? '60');
    _selectedSportType = widget.venue?.sportType ?? 'Futsal';
  }

  @override
  void dispose() {
    // Clean up all controllers
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Safety check
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      setState(() { _isLoading = false; });
      return;
    }

    try {
      // Prepare the data map to be saved
      final venueData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'pricePerHour': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'openingTime': _openingTimeController.text.trim(),
        'closingTime': _closingTimeController.text.trim(),
        'slotDuration': int.tryParse(_slotDurationController.text.trim()) ?? 60,
        'sportType': _selectedSportType,
        'managerId': user.uid, // Set the owner of the venue
      };
      
      // If we are in "add" mode, create a new document.
      if (widget.formMode == FormMode.add) {
        await FirebaseFirestore.instance.collection('venues').add(venueData);
      } 
      // If we are in "edit" mode, update the existing document.
      else if (widget.venue != null) {
        await FirebaseFirestore.instance.collection('venues').doc(widget.venue!.id).update(venueData);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Go back to the previous screen after saving
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save venue: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The title changes based on whether we are adding or editing
        title: Text(widget.formMode == FormMode.add ? 'Add New Venue' : 'Edit Venue'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveForm,
            icon: const Icon(Icons.save),
            tooltip: 'Save Venue',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView( // Use ListView to prevent overflow on small screens
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Venue Name'),
                      validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a name.' : null,
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a location.' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price Per Hour'),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value?.isEmpty ?? true) || double.tryParse(value!) == null ? 'Please enter a valid price.' : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSportType,
                      decoration: const InputDecoration(labelText: 'Sport Type'),
                      items: ['Futsal', 'Cricket', 'Badminton', 'Other'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() { _selectedSportType = newValue!; });
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    TextFormField(
                      controller: _openingTimeController,
                      decoration: const InputDecoration(labelText: 'Opening Time (HH:mm)', hintText: 'e.g., 09:00'),
                      validator: (value) => (value?.isEmpty ?? true) || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value!) ? 'Enter a valid time (HH:mm).' : null,
                    ),
                    TextFormField(
                      controller: _closingTimeController,
                      decoration: const InputDecoration(labelText: 'Closing Time (HH:mm)', hintText: 'e.g., 21:00'),
                      validator: (value) => (value?.isEmpty ?? true) || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value!) ? 'Enter a valid time (HH:mm).' : null,
                    ),
                    TextFormField(
                      controller: _slotDurationController,
                      decoration: const InputDecoration(labelText: 'Slot Duration (minutes)'),
                      keyboardType: TextInputType.number,
                       validator: (value) => (value?.isEmpty ?? true) || int.tryParse(value!) == null ? 'Enter a valid duration.' : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}