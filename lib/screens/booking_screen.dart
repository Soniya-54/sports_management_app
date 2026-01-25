// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import '../models/venue_model.dart';
import 'payment_screen.dart';

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

  // Time slot state variables (now dynamic)
  List<String> _timeSlots = [];
  String? _selectedTimeSlot;
  var _isBooking = false;

  // State variables to handle booked slots
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
      // Filter only confirmed or pending_verification bookings
      final bookedTimes = querySnapshot.docs
          .where((doc) {
            final status = doc['bookingStatus'] as String?;
            return status == 'confirmed' || status == 'pending_verification';
          })
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

  Future<void> _confirmBooking() async {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to book.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // Fetch venue details to get managerId
      final venueDoc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(widget.venue.id)
          .get();

      final venueData = venueDoc.data();
      final managerId = venueData?['managerId'] as String?;

      if (managerId == null) {
        throw Exception('Venue manager information not found');
      }

      // Create a pending booking (not confirmed until payment)
      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'userId': user.uid,
            'userEmail': user.email,
            'venueId': widget.venue.id,
            'venueName': widget.venue.name,
            'venueManagerId': managerId,
            'bookingDate': Timestamp.fromDate(_selectedDay!),
            'timeSlot': _selectedTimeSlot,
            'totalPrice': widget.venue.pricePerHour,
            'bookingStatus':
                'pending', // Status will change to 'confirmed' after payment
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Navigate to payment screen
      if (mounted) {
        final paymentSuccess = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId: bookingRef.id,
              amount: widget.venue.pricePerHour,
              venueName: widget.venue.name,
              venueManagerId: managerId,
            ),
          ),
        );

        // If payment was successful, update UI
        if (paymentSuccess == true) {
          final bookedDay = _selectedDay;
          setState(() {
            _selectedTimeSlot = null;
          });
          _fetchBookedSlots(bookedDay!);
        } else {
          // If payment failed or was cancelled, delete the pending booking
          await bookingRef.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: $error'),
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
      appBar: AppBar(title: Text('Book ${widget.venue.name}')),
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
              'Select a Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _timeSlots.isEmpty
                ? const Center(
                    child: Text('No available slots for this venue.'),
                  )
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
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isBooked
                              ? Colors.grey[400]
                              : Colors.grey[200],
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.black,
                          // Reduce vertical padding and allow the button to shrink so
                          // the time text does not get clipped. This overrides the
                          // app-wide padding which was increased globally.
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 8.0,
                          ),
                          minimumSize: const Size(0, 0),
                          textStyle: const TextStyle(fontSize: 14),
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
