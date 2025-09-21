// lib/screens/player_tabs_screen.dart

import 'package:flutter/material.dart';
import 'venue_list_screen.dart';
import 'my_bookings_screen.dart';
import 'team_finder_screen.dart'; // <-- 1. IMPORT THE NEW SCREEN

class PlayerTabsScreen extends StatefulWidget {
  const PlayerTabsScreen({super.key});

  @override
  State<PlayerTabsScreen> createState() => _PlayerTabsScreenState();
}

class _PlayerTabsScreenState extends State<PlayerTabsScreen> {
  int _selectedPageIndex = 0;

  // V-- 2. ADD THE NEW SCREEN TO THE LIST OF PAGES --V
  final List<Widget> _pages = [
    const VenueListScreen(),
    const TeamFinderScreen(), // The new screen is now the second tab
    const MyBookingsScreen(),
  ];

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        // Increase the font size for selected items for better visibility
        selectedFontSize: 14,
        // V-- 3. ADD THE NEW ITEM TO THE NAVIGATION BAR --V
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Venues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add_outlined),
            activeIcon: Icon(Icons.group_add),
            label: 'Find Team',
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