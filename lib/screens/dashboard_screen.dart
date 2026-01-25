// lib/screens/dashboard_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sports_management_app/screens/venue_list_screen.dart';
import 'player_tabs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Future<QuerySnapshot?>? _upcomingBookingsFuture;
  Future<DocumentSnapshot?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingBookings();
    _fetchUserData();
  }

  void _fetchUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userFuture = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
      });
    }
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
            .where(
              'bookingDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
            )
            .where('bookingStatus', isEqualTo: 'confirmed')
            .orderBy('bookingDate', descending: false)
            .limit(1) // Fetch only the very next booking
            .get();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the default AppBar
      body: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120.0,
              backgroundColor: const Color(0xFF80B918),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                title: FutureBuilder<DocumentSnapshot?>(
                  future: _userFuture,
                  builder: (context, snapshot) {
                    String name;
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data!.exists) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final fetchedName = userData['name'] as String?;
                      if (fetchedName != null && fetchedName.isNotEmpty) {
                        name = fetchedName.split(' ')[0];
                      } else {
                        final user = FirebaseAuth.instance.currentUser;
                        name = user?.email?.split('@')[0] ?? 'User';
                      }
                    } else {
                      final user = FirebaseAuth.instance.currentUser;
                      name = user?.email?.split('@')[0] ?? 'User';
                    }
                    final capitalizedName = name.isNotEmpty
                        ? name[0].toUpperCase() + name.substring(1)
                        : '';
                    return Text(
                      'Welcome back, $capitalizedName!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    );
                  },
                ),
                background: Container(color: const Color(0xFF80B918)),
              ),
              actions: [
                IconButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<QuerySnapshot?>(
                      future: _upcomingBookingsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const _ErrorCard(
                            message: 'Error loading bookings.',
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _NoBookingsCard(
                            onBookVenue: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => const VenueListScreen(),
                                ),
                              );
                              refresh();
                            },
                          );
                        }
                        final bookingDoc = snapshot.data!.docs.first;
                        return _BookingCard(
                          bookingId: bookingDoc.id,
                          bookingData:
                              bookingDoc.data() as Map<String, dynamic>,
                          onMarkedDone: refresh,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Book a Venue',
                            icon: Icons.calendar_month_outlined,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => const VenueListScreen(),
                                ),
                              );
                              refresh();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            title: 'Find a Team',
                            icon: Icons.group_outlined,
                            onTap: () {
                              context
                                  .findAncestorStateOfType<
                                    PlayerTabsScreenState
                                  >()
                                  ?.selectPage(1);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Events',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .findAncestorStateOfType<
                                  PlayerTabsScreenState
                                >()
                                ?.selectPage(2);
                          },
                          child: const Text('View All Events'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _EventCard(), // Placeholder for event card
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBookingsCard extends StatelessWidget {
  final VoidCallback onBookVenue;
  const _NoBookingsCard({required this.onBookVenue});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              "No upcoming bookings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Pull down to refresh or ",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: onBookVenue,
                  child: Text(
                    "book a venue!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final VoidCallback onMarkedDone;

  const _BookingCard({
    required this.bookingId,
    required this.bookingData,
    required this.onMarkedDone,
  });

  @override
  Widget build(BuildContext context) {
    final bookingDate = (bookingData['bookingDate'] as Timestamp).toDate();
    final formattedDate = DateFormat('MMM d, yyyy').format(bookingDate);
    final formattedTime = bookingData['timeSlot'] ?? 'N/A';
    final venueName = bookingData['venueName'] ?? 'No Venue Name';
    final venueId = bookingData['venueId'];
    final totalPrice = (bookingData['totalPrice'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<DocumentSnapshot>(
        future: venueId != null
            ? FirebaseFirestore.instance.collection('venues').doc(venueId).get()
            : null,
        builder: (context, snapshot) {
          String imageUrl = '';
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data!.exists) {
            final venueData = snapshot.data!.data() as Map<String, dynamic>;
            imageUrl = venueData['imageUrl'] ?? '';
          }

          return Stack(
            children: [
              // Background Image
              if (imageUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.sports,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              // Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF213300).withOpacity(0.9),
                        const Color(0xFF80B918).withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Mark-done button (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withOpacity(0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mark booking completed?'),
                          content: const Text(
                            'Mark this booking as completed and remove it from the dashboard?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;

                      try {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(bookingId)
                            .update({
                              'bookingStatus': 'completed',
                              'completedAt': FieldValue.serverTimestamp(),
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking marked completed'),
                          ),
                        );
                        onMarkedDone();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update booking: $e'),
                          ),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.check_box_outline_blank,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Next Booking:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      venueName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard();

  @override
  Widget build(BuildContext context) {
    // Placeholder data - replace with actual event data from Firestore
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            'https://www.shutterstock.com/image-vector/vector-illustration-badminton-athlete-jumping-600nw-2520932405.jpg', // Placeholder image
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Everest Badminton Championship',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sept 30, 2025',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text('9:00 AM', style: TextStyle(color: Colors.grey[800])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Dhuku Futsal Hub',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(message, style: TextStyle(color: Colors.red.shade900)),
        ),
      ),
    );
  }
}
