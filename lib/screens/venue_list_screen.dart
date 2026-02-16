// lib/screens/venue_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sports_management_app/screens/my_bookings_screen.dart';
import '../models/venue_model.dart';
import 'venue_detail_screen.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  String? _selectedSport; // null means "All"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Venue'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const MyBookingsScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('My Bookings'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('venues').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No venues available.'));
          }

          final venues = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Venue(
              id: doc.id,
              name: data['name'] ?? 'No Name',
              location: data['location'] ?? 'No Location',
              sportType: data['sportType'] ?? 'N/A',
              pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
              imageUrl: data['imageUrl'] ?? '',
              description: data['description'] ?? '',
              openingTime: data['openingTime'] ?? '09:00',
              closingTime: data['closingTime'] ?? '21:00',
              slotDuration: (data['slotDuration'] as num?)?.toInt() ?? 60,
            );
          }).toList();

          // Get unique sport types for filters
          final allSportTypes = venues.map((v) => v.sportType).toSet().toList();
          allSportTypes.sort();

          // Filter venues based on selected sport
          final filteredVenues = _selectedSport == null
              ? venues
              : venues.where((v) => v.sportType == _selectedSport).toList();

          return Column(
            children: [
              // Sport filter chips
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All" filter chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _selectedSport == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSport = null;
                            });
                          },
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                        ),
                      ),
                      // Individual sport filter chips
                      ...allSportTypes.map((sport) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(sport),
                            selected: _selectedSport == sport,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSport = selected ? sport : null;
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              // Venue list
              Expanded(
                child: filteredVenues.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedSport ?? ''} venues available.',
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredVenues.length,
                        itemBuilder: (context, index) {
                          final venue = filteredVenues[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        VenueDetailScreen(venue: venue),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: venue.id,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: SizedBox(
                                        height: 150,
                                        width: double.infinity,
                                        child: Image.network(
                                          venue.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.sports,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          venue.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          venue.location,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              venue.sportType,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Rs. ${venue.pricePerHour.toStringAsFixed(0)}/hr',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
