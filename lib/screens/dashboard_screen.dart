// lib/screens/dashboard_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'venue_list_screen.dart';
import 'player_tabs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Future<QuerySnapshot?>? _upcomingBookingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingBookings();
  }

  void refresh() {
    if (mounted) {
      _fetchUpcomingBookings();
    }
  }

  void _fetchUpcomingBookings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      setState(() {
        _upcomingBookingsFuture = FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
            .where('bookingStatus', isEqualTo: 'confirmed')
            .orderBy('bookingDate', descending: false)
            .get();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String welcomeName = user?.email?.split('@')[0] ?? 'Player';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $welcomeName!'),
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout), tooltip: 'Logout'),
        ],
      ),
      body: RefreshIndicator( // Added RefreshIndicator for pull-to-refresh
        onRefresh: () async {
          refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FutureBuilder<QuerySnapshot?>(
              future: _upcomingBookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Checking for upcoming bookings..."))));
                }
                if (snapshot.hasError) {
                  return Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('Error loading bookings. Check the debug console.'))));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _NoBookingsCard();
                }
                final bookingDocs = snapshot.data!.docs;
                return _BookingCarousel(bookingDocs: bookingDocs, onRefresh: refresh);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: 'Book a Venue', icon: Icons.sports_soccer,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const VenueListScreen()));
                      refresh();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    title: 'Find a Team', icon: Icons.group_add,
                    onTap: () { context.findAncestorStateOfType<PlayerTabsScreenState>()?.selectPage(1); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ActionCard(
              title: 'Browse Events', icon: Icons.emoji_events,
              onTap: () { context.findAncestorStateOfType<PlayerTabsScreenState>()?.selectPage(2); },
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCarousel extends StatelessWidget {
  final List<QueryDocumentSnapshot> bookingDocs;
  final VoidCallback onRefresh;
  const _BookingCarousel({required this.bookingDocs, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Upcoming Bookings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 150,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: bookingDocs.length,
              itemBuilder: (context, index) {
                final bookingDoc = bookingDocs[index];
                final bookingData = bookingDoc.data() as Map<String, dynamic>;
                return _BookingCard(
                  bookingId: bookingDoc.id,
                  bookingData: bookingData,
                  onMarkedDone: onRefresh,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NoBookingsCard extends StatelessWidget {
  const _NoBookingsCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            const Text("No upcoming bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Pull down to refresh or book a venue!", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// V-- THIS IS THE UPDATED BOOKING CARD WIDGET --V
class _BookingCard extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final VoidCallback onMarkedDone;

  const _BookingCard({
    required this.bookingId,
    required this.bookingData,
    required this.onMarkedDone,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _isCompleting = false;

  Future<void> _markAsDone() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'bookingStatus': 'completed',
      });
      
      // A short delay so the user can see the checkmark animation
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked as completed!'), backgroundColor: Colors.green),
        );
      }
      widget.onMarkedDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking: $e'), backgroundColor: Colors.red),
        );
        setState(() { // Reset on failure
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingDate = (widget.bookingData['bookingDate'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMd().format(bookingDate);
    final bool isToday = DateTime.now().day == bookingDate.day &&
                         DateTime.now().month == bookingDate.month &&
                         DateTime.now().year == bookingDate.year;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'YOUR NEXT BOOKING: TODAY' : 'UPCOMING BOOKING',
                  style: Theme.of(context).textTheme.labelLarge
                ),
                const Spacer(),
                Text(
                  widget.bookingData['venueName'] ?? 'No Venue Name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text('$formattedDate at ${widget.bookingData['timeSlot']}', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ],
            ),
            Positioned(
              top: -12,
              right: -12,
              child: IconButton(
                // Use AnimatedSwitcher for a smooth cross-fade between icons
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isCompleting
                      ? Icon( // The "filled" icon when processing
                          Icons.check_circle,
                          key: const ValueKey('completed'),
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon( // The "unfilled" icon by default
                          Icons.check_circle_outline,
                          key: const ValueKey('incomplete'),
                          color: Colors.grey[600],
                        ),
                ),
                tooltip: 'Mark as Done',
                onPressed: _isCompleting ? null : _markAsDone, // Disable button while processing
              ),
            ),
          ],
        ),
      ),
    );
  }
}