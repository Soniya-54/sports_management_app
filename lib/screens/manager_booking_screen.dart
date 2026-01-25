// lib/screens/manager_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/venue_model.dart';

class ManagerBookingScreen extends StatefulWidget {
  final Venue venue;
  const ManagerBookingScreen({super.key, required this.venue});

  @override
  State<ManagerBookingScreen> createState() => _ManagerBookingScreenState();
}

class _ManagerBookingScreenState extends State<ManagerBookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<String> _timeSlots = [];
  String? _selectedTimeSlot;
  var _isBooking = false;

  List<String> _bookedSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _generateTimeSlots();
    _fetchBookedSlots(_selectedDay!);
  }

  void _generateTimeSlots() {
    final timeFormat = DateFormat('hh:mm a');
    final opening = TimeOfDay(
      hour: int.parse(widget.venue.openingTime.split(':')[0]),
      minute: int.parse(widget.venue.openingTime.split(':')[1]),
    );
    final closing = TimeOfDay(
      hour: int.parse(widget.venue.closingTime.split(':')[0]),
      minute: int.parse(widget.venue.closingTime.split(':')[1]),
    );
    List<String> slots = [];
    TimeOfDay currentTime = opening;
    while (currentTime.hour < closing.hour ||
        (currentTime.hour == closing.hour &&
            currentTime.minute < closing.minute)) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        currentTime.hour,
        currentTime.minute,
      );
      slots.add(timeFormat.format(dt));
      final newTimeMinutes =
          currentTime.hour * 60 +
          currentTime.minute +
          widget.venue.slotDuration;
      currentTime = TimeOfDay(
        hour: newTimeMinutes ~/ 60,
        minute: newTimeMinutes % 60,
      );
    }
    setState(() {
      _timeSlots = slots;
    });
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _bookedSlots = [];
    });
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('venueId', isEqualTo: widget.venue.id)
          .where('bookingDate', isGreaterThanOrEqualTo: startOfDay)
          .where('bookingDate', isLessThanOrEqualTo: endOfDay)
          .get();
      final bookedTimes = querySnapshot.docs
          .map((doc) => doc['timeSlot'] as String)
          .toList();
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

  Future<void> _blockSlot() async {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot to block.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _isBooking = true;
    });
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userEmail': 'walk-in/phone',
        'venueId': widget.venue.id,
        'venueName': widget.venue.name,
        'bookingDate': Timestamp.fromDate(_selectedDay!),
        'timeSlot': _selectedTimeSlot,
        'totalPrice': widget.venue.pricePerHour,
        'bookingStatus': 'confirmed',
        'bookingType': 'walk-in',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final bookedTime = _selectedTimeSlot;
      final bookedDay = _selectedDay;
      setState(() {
        _selectedTimeSlot = null;
      });
      _fetchBookedSlots(bookedDay!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully blocked slot for $bookedTime!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block slot: $error'),
            backgroundColor: Colors.red,
          ),
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
      appBar: AppBar(title: Text('Manage Slots: ${widget.venue.name}')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedTimeSlot = null;
              });
              _fetchBookedSlots(selectedDay);
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
            child: Text(
              'Select a Time Slot to Block/Manage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = _timeSlots[index];
                      final isSelected = timeSlot == _selectedTimeSlot;
                      final isBooked = _bookedSlots.contains(timeSlot);
                      return ElevatedButton(
                        onPressed: isBooked
                            ? null
                            : () {
                                setState(() {
                                  _selectedTimeSlot = timeSlot;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isBooked
                              ? Colors.grey[400]
                              : Colors.grey[200],
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.black,
                          textStyle: const TextStyle(fontSize: 12),
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
                    onPressed: _blockSlot,
                    // V-- THIS IS THE UPDATED STYLE SECTION --V
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // The button's background color will match the primary theme color (green in our case)
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      // The text and icon color on the button will be white
                      foregroundColor: Colors.white,
                    ),
                    // ^-- END OF UPDATED STYLE SECTION --^
                    child: const Text('Block Selected Time Slot'),
                  ),
          ),
        ],
      ),
    );
  }
}
