// lib/screens/add_edit_event_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

enum EventFormMode { add, edit }

class AddEditEventScreen extends StatefulWidget {
  final EventFormMode formMode;
  final Event? event;

  const AddEditEventScreen({
    super.key,
    required this.formMode,
    this.event,
  });

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _venueNameController;
  late TextEditingController _entryFeeController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _imageUrlController = TextEditingController(text: widget.event?.imageUrl ?? '');
    _venueNameController = TextEditingController(text: widget.event?.venueName ?? '');
    _entryFeeController = TextEditingController(text: widget.event?.entryFee.toString() ?? '');
    _selectedDate = widget.event?.eventDate.toDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _venueNameController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() { _selectedDate = pickedDate; });
    }
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields.')));
      return;
    }

    setState(() { _isLoading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return; // Should not happen
    }

    try {
      final eventData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'venueName': _venueNameController.text.trim(),
        'entryFee': double.tryParse(_entryFeeController.text.trim()) ?? 0.0,
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'managerId': user.uid,
      };

      if (widget.formMode == EventFormMode.add) {
        await FirebaseFirestore.instance.collection('events').add(eventData);
      } else if (widget.event != null) {
        await FirebaseFirestore.instance.collection('events').doc(widget.event!.id).update(eventData);
      }

      if (mounted) { Navigator.of(context).pop(); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save event: $e'))); }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formMode == EventFormMode.add ? 'Add New Event' : 'Edit Event'),
        actions: [
          IconButton(onPressed: _isLoading ? null : _saveForm, icon: const Icon(Icons.save)),
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
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Event Name'),
                      validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a name.' : null,
                    ),
                    TextFormField(
                      controller: _venueNameController,
                      decoration: const InputDecoration(labelText: 'Venue Name'),
                       validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a venue name.' : null,
                    ),
                    TextFormField(
                      controller: _entryFeeController,
                      decoration: const InputDecoration(labelText: 'Entry Fee'),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value?.isEmpty ?? true) || double.tryParse(value!) == null ? 'Please enter a valid fee.' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                    ),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_selectedDate == null ? 'No date chosen' : 'Date: ${DateFormat.yMd().format(_selectedDate!)}'),
                        ),
                        TextButton(onPressed: _presentDatePicker, child: const Text('Choose Date')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}