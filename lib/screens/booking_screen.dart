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
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', 
    '03:00 PM', '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM',
  ];
  String? _selectedTimeSlot;
  var _isBooking = false;

  // NEW: State variables to handle booked slots
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Fetch booked slots for the initial day when the screen loads
    _fetchBookedSlots(_selectedDay!);
  }

  // NEW: Function to fetch booked slots from Firestore for a specific date
  Future<void> _fetchBookedSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _bookedSlots = []; // Clear previous day's slots
    });

    // We query for a date range from the start of the day to the end of the day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('venueId', isEqualTo: widget.venue.id)
          .where('bookingDate', isGreaterThanOrEqualTo: startOfDay)
          .where('bookingDate', isLessThanOrEqualTo: endOfDay)
          .get();

      final bookedTimes = querySnapshot.docs.map((doc) => doc['timeSlot'] as String).toList();
      
      setState(() {
        _bookedSlots = bookedTimes;
        _isLoadingSlots = false;
      });
    } catch (e) {
      print("Error fetching booked slots: $e");
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _confirmBooking() async {
  // Validation and user checks remain the same.
  if (_selectedDay == null || _selectedTimeSlot == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a date and time slot.'), backgroundColor: Colors.red),
    );
    return;
  }
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in to book.'), backgroundColor: Colors.red),
    );
    return;
  }
  
  setState(() {
    _isBooking = true;
  });

  try {
    // Save the new booking to Firestore.
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

    // V-- THIS IS THE NEW USER EXPERIENCE LOGIC --V

    // 1. Store the successful booking details in temporary variables.
    final bookedTime = _selectedTimeSlot;
    final bookedDay = _selectedDay;

    // 2. Clear the user's current time selection.
    setState(() {
      _selectedTimeSlot = null;
    });

    // 3. Re-fetch all booked slots for the selected day. This will now include the new one.
    _fetchBookedSlots(bookedDay!);

    // 4. Show a non-disruptive SnackBar confirmation instead of a dialog.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully booked for $bookedTime!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    // ^-- END OF NEW LOGIC --^

  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create booking: $error'), backgroundColor: Colors.red),
      );
    }
  } finally {
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
                _selectedTimeSlot = null; // Reset selected time when day changes
              });
              // NEW: Fetch bookings for the newly selected day
              _fetchBookedSlots(selectedDay);
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() { _calendarFormat = format; });
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

          // NEW: We now show a loading spinner while fetching slots, then the grid.
          Expanded(
            child: _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
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
                      // NEW: Check if the slot is already booked
                      final isBooked = _bookedSlots.contains(timeSlot);

                      return ElevatedButton(
                        // NEW: onPressed is null if the slot is already booked, disabling the button
                        onPressed: isBooked
                            ? null
                            : () {
                                setState(() {
                                  _selectedTimeSlot = timeSlot;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isBooked
                                ? Colors.grey[400] // Disabled color for booked slots
                                : Colors.grey[200], // Default color for available slots
                          foregroundColor: isSelected ? Colors.white : Colors.black,
                        ),
                        child: Text(timeSlot),
                      );
                    },
                  ),
          ),
          
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