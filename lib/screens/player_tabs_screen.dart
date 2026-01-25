// lib/screens/player_tabs_screen.dart

import 'package:flutter/material.dart';
import 'package:sports_management_app/screens/venue_list_screen.dart';
import 'dashboard_screen.dart';
import 'team_finder_screen.dart';
import 'events_screen.dart';

class PlayerTabsScreen extends StatefulWidget {
  const PlayerTabsScreen({super.key});

  @override
  State<PlayerTabsScreen> createState() => PlayerTabsScreenState();
}

class PlayerTabsScreenState extends State<PlayerTabsScreen> {
  int _selectedPageIndex = 0;

  // The key must be for the STATE of the dashboard, not the widget itself.
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(key: _dashboardKey), // 0: Home
      const VenueListScreen(), // 1: Book a Venue
      const TeamFinderScreen(), // 2: Find Team
      const EventsScreen(), // 3: Events
    ];
  }

  void selectPage(int index) {
    if (index < 0 || index >= _pages.length) return;

    // When the user taps a tab, check if they are going to the Home tab (index 0)
    if (index == 0) {
      // Use the key to call the public 'refresh' method on the dashboard.
      _dashboardKey.currentState?.refresh();
    }

    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedPageIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        onTap: selectPage,
        currentIndex: _selectedPageIndex,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Book a Venue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Find Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Events',
          ),
        ],
      ),
    );
  }
}
