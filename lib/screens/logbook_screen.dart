// lib/screens/logbook_screen.dart

import 'package:drive_buddy/models/car_model.dart';
import 'package:flutter/material.dart';

class LogbookScreen extends StatelessWidget {
  // We add this 'car' property to hold the data passed from the dashboard
  final Car car;

  const LogbookScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'LOG BOOK', // [cite: 661]
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
              child: const Text(
                'D',
                style: TextStyle(color: Colors.white),
              ), // [cite: 668]
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Plate Number Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 40,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                car.plateNumber, // [cite: 662]
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Car Details Section
            _buildDetailRow('Model', car.model), // [cite: 656]
            _buildDetailRow('Make', car.brand), // [cite: 657]
            _buildDetailRow(
              'Odometer',
              '${car.currentMileage} km',
            ), // [cite: 658]
            _buildDetailRow('Tire Size', car.tireSize ?? 'N/A'), // [cite: 659]
            _buildDetailRow('Engine', car.engine ?? 'N/A'), // [cite: 660]
            _buildDetailRow(
              'Last Service',
              car.lastService ?? 'N/A',
            ), // [cite: 663]

            const SizedBox(height: 40),

            // 3. Reminder Section [cite: 664]
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reminder!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Static reminder cards as per your design
            _buildReminderCard(
              'Occasionally: Harsh Braking', // [cite: 665]
              Colors.yellow.shade700,
            ),
            _buildReminderCard(
              'Frequently: Aggressive Cornering', // [cite: 666]
              Colors.red.shade700,
            ),
          ],
        ),
      ),
      // 4. Custom Bottom Bar for "Start Driving"
      // This mimics the "steering wheel" button in your design [cite: 666]
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // TODO: Navigate to the "Start Driving" screen/session
              Navigator.of(
                context,
              ).pushNamed('/driving_session', arguments: car);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.all(16),
              shape: const CircleBorder(),
            ),
            child: const Icon(
              Icons.drive_eta_outlined, // A steering wheel-like icon
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for a single detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100, // Fixed width for labels
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for reminder cards
  Widget _buildReminderCard(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
