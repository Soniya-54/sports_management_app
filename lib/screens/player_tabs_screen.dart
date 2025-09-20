// lib/screens/tabs_screen.dart

import 'package:flutter/material.dart';
import 'venue_list_screen.dart';
import 'my_bookings_screen.dart'; // We will create this file next

class PlayerTabsScreen extends StatefulWidget {
  const PlayerTabsScreen({super.key});

  @override
  State<PlayerTabsScreen> createState() => _PlayerTabsScreenState();
}

class _PlayerTabsScreenState extends State<PlayerTabsScreen> {
  int _selectedPageIndex = 0; // Index of the currently selected tab

  // List of the main screens of our app
  final List<Widget> _pages = [
    const VenueListScreen(),
    const MyBookingsScreen(), // We will create this screen next
  ];

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will be the currently selected page from our _pages list
      body: _pages[_selectedPageIndex],
      // The BottomNavigationBar is the bar at the bottom
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer), // A different icon when selected
            label: 'Venues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'My Bookings',
          ),
        ],
      ),
    );
  }
}