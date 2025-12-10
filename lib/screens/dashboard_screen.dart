// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:drive_buddy/screens/car_list_screen.dart';
import 'package:drive_buddy/screens/chat_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Define the views for each tab
  static const List<Widget> _widgetOptions = <Widget>[
    CarListScreen(), // Tab 0: Home (List of cars)
    ChatSelectionScreen(), // Tab 1: Chat (Select car to chat)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'DRIVE BUDDY',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Hides the back button (since we logged in)
        // --- PROFILE BUTTON ---
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            tooltip: 'My Profile',
          ),
          const SizedBox(width: 12), // Padding from right edge
        ],
      ),

      // Display the selected tab
      body: _widgetOptions.elementAt(_selectedIndex),

      // --- ADD CAR BUTTON (Only visible on Home Tab) ---
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/add_car');
              },
              backgroundColor: Colors.grey.shade800,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null, // Hide button on Chat tab
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Cars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false, // Clean look
        showUnselectedLabels: false,
      ),
    );
  }
}
