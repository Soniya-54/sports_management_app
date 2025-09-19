// lib/screens/venue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:sports_management_app/screens/booking_screen.dart';
import '../models/venue_model.dart';

class VenueDetailScreen extends StatelessWidget {
  final Venue venue;
  const VenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: screenSize.height * 0.35,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              title: Text(
                venue.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
              ),
              background: Hero(
                tag: venue.id, // The tag must be unique (venue ID is perfect)
                child: Image.network(
                  venue.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Show a placeholder icon if the image URL is invalid or fails to load
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.sports_soccer, size: 100, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${venue.sportType} in ${venue.location}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Rs. ${venue.pricePerHour.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '/ hour',
                         style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ),
                      const Divider(height: 32, thickness: 1),
                      const Text(
                        'About this venue',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        venue.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 120), // Pushes content up from the button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating button that stays at the bottom
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookingScreen(venue: venue),
            ),
          );
        },
        label: const Text('Book Now'),
        icon: const Icon(Icons.calendar_today),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}