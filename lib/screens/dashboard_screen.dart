// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:drive_buddy/models/car_model.dart'; // Import Car model

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // To track the active tab in the BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Add navigation to Chatbot screen when index is 1
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // The AppBar title "DASHBOARD" [cite: 617]
        title: const Text(
          'DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        // Profile Icon on the right [cite: 618]
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
            // Greeting text "Hi!" [cite: 619] and "Choose Your Car" [cite: 620]
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

            // Car list
            Expanded(
              // Use ValueListenableBuilder to listen for changes in the 'cars' box
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
                      // Pass the whole Car object to the helper
                      return _buildCarButton(car);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button to add a new car [cite: 624]
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamed('/add_car'); // TODO: Navigate to Add New Car screen
        },
        backgroundColor: Colors.grey.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar with icons for Dashboard and Chatbot
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Cars',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Helper widget for the car selection buttons [cite: 621, 622, 623]
  Widget _buildCarButton(Car car) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // TODO: Navigate to the Logbook screen for this car
            // We can now pass the car object, e.g.:
            // Navigator.of(context).pushNamed('/logbook', arguments: car);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            car.plateNumber, // Display the plate number
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
