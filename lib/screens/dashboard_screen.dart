// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drive_buddy/models/car_model.dart';
import 'package:drive_buddy/screens/chatbot_screen.dart'; // Import the chatbot
import 'package:drive_buddy/screens/chat_selection_screen.dart'; // Import the chat selection screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // 0 for Cars, 1 for Chat

  // This list will hold our two main screens
  static const List<Widget> _widgetOptions = <Widget>[
    CarListScreen(), // A new widget for just the car list
    ChatSelectionScreen(), // Our new chatbot screen
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
      // The body will now switch between the screens in _widgetOptions
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/add_car');
              },
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // This hides the button on the Chatbot screen

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Cars',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // This now works!
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// *** CREATE THIS NEW WIDGET ***
// We're moving the Car List UI into its own stateless widget
// to keep the DashboardScreen clean.
class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: const Text('D', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Hi!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Choose Your Car',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Car>('cars').listenable(),
                builder: (context, Box<Car> box, _) {
                  final cars = box.values.toList().cast<Car>();
                  if (cars.isEmpty) {
                    return Center(
                      child: Text(
                        "Tap the '+' button to add your first car!",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      final car = cars[index];
                      return _buildCarButton(context, car); // Pass context
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the car selection buttons
  Widget _buildCarButton(BuildContext context, Car car) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/logbook', arguments: car);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            car.plateNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
