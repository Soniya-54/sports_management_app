// lib/screens/search_selection_screen.dart

import 'package:flutter/material.dart';
import '../models/venue_model.dart'; // We are making it specific to Venues for now

class SearchSelectionScreen extends StatefulWidget {
  // We pass in the list of all available items to search from
  final List<Venue> allVenues;

  const SearchSelectionScreen({super.key, required this.allVenues});

  @override
  State<SearchSelectionScreen> createState() => _SearchSelectionScreenState();
}

class _SearchSelectionScreenState extends State<SearchSelectionScreen> {
  // This list will hold the items that match the search query
  List<Venue> _filteredVenues = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initially, the filtered list is the full list
    _filteredVenues = widget.allVenues;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // The search logic
  void _runFilter(String enteredKeyword) {
    List<Venue> results = [];
    if (enteredKeyword.isEmpty) {
      results = widget.allVenues;
    } else {
      results = widget.allVenues
          .where((venue) =>
              venue.name.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              venue.location.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _filteredVenues = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Venue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // The Search Bar
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: const InputDecoration(
                labelText: 'Search by name or location',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // The List of Results
            Expanded(
              child: _filteredVenues.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredVenues.length,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          title: Text(_filteredVenues[index].name),
                          subtitle: Text(_filteredVenues[index].location),
                          onTap: () {
                            // When a user taps an item, we pop the screen
                            // and return the selected Venue object
                            Navigator.of(context).pop(_filteredVenues[index]);
                          },
                        ),
                      ),
                    )
                  : const Text(
                      'No results found',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}