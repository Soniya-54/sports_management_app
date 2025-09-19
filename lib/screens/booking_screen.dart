// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/venue_model.dart';

class BookingScreen extends StatefulWidget {
  final Venue venue;
  const BookingScreen({super.key, required this.venue});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Calendar state variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Time slot state variables
  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM',
    '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM',
  ];
  String? _selectedTimeSlot;
  var _isBooking = false; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _confirmBooking() async {
    // Basic validation to ensure a date and time are selected.
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Safety check to ensure a user is logged in.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Set the loading state to true to show the spinner.
    setState(() {
      _isBooking = true;
    });

    try {
      // Add a new document to the 'bookings' collection in Firestore.
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userEmail': user.email,
        'venueId': widget.venue.id,
        'venueName': widget.venue.name,
        'bookingDate': Timestamp.fromDate(_selectedDay!),
        'timeSlot': _selectedTimeSlot,
        'totalPrice': widget.venue.pricePerHour,
        'bookingStatus': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // If the write to the database is successful, show a confirmation dialog.
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Booking Successful!'),
            content: Text('You have booked ${widget.venue.name} on ${_selectedDay!.toLocal().toString().split(' ')[0]} at $_selectedTimeSlot.'),
            actions: [
              TextButton(
                onPressed: () {
                  // This pops three times to go from:
                  // Dialog -> Booking Screen -> Detail Screen -> Venue List
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      // If there's an error writing to the database, show an error message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create booking: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // No matter what happens, set the loading state back to false.
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.venue.name}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This is the full, unabbreviated TableCalendar widget.
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 1)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Select a Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // This is the full, unabbreviated GridView for time slots.
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _timeSlots[index];
                final isSelected = timeSlot == _selectedTimeSlot;

                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTimeSlot = timeSlot;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                  ),
                  child: Text(timeSlot),
                );
              },
            ),
          ),
          // This is the full, unabbreviated confirm button with loading logic.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isBooking
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirm Booking'),
                  ),
          ),
        ],
      ),
    );
  }
}