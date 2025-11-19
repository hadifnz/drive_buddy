// lib/screens/logbook_screen.dart

import 'package:drive_buddy/models/car_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:drive_buddy/models/trip_session_model.dart'; // Import TripSession
import 'package:intl/intl.dart'; // For formatting dates

class LogbookScreen extends StatelessWidget {
  final Car car;

  const LogbookScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'LOG BOOK',
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
                car.plateNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Car Details Section
            // We use a ValueListenableBuilder to show the
            // car's mileage update in real-time after a trip.
            ValueListenableBuilder(
              valueListenable: Hive.box<Car>(
                'cars',
              ).listenable(keys: [car.key]),
              builder: (context, Box<Car> box, _) {
                // Get the most up-to-date version of the car
                final updatedCar = box.get(car.key);

                if (updatedCar == null) {
                  return const Center(
                    child: Text(
                      "Car data not available",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildDetailRow('Model', updatedCar.model),
                    _buildDetailRow('Make', updatedCar.brand),
                    _buildDetailRow(
                      'Odometer',
                      '${updatedCar.currentMileage.toStringAsFixed(1)} km',
                    ),
                    _buildDetailRow('Tire Size', updatedCar.tireSize ?? 'N/A'),
                    _buildDetailRow('Engine', updatedCar.engine ?? 'N/A'),
                    _buildDetailRow(
                      'Last Service',
                      updatedCar.lastService ?? 'N/A',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // 3. Reminder Section
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
              'Occasionally: Harsh Braking',
              Colors.yellow.shade700,
            ),
            _buildReminderCard(
              'Frequently: Aggressive Cornering',
              Colors.red.shade700,
            ),

            const SizedBox(height: 40),

            // 4. Trip History Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trip History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildTripHistoryList(),
          ],
        ),
      ),
      // 5. Custom Bottom Bar for "Start Driving"
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
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

  // Helper widget to build the list of past trips
  Widget _buildTripHistoryList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<TripSession>('trip_sessions').listenable(),
      builder: (context, Box<TripSession> box, _) {
        // Filter trips to only show for the current car, sorted by date
        final trips = box.values
            .where((trip) => trip.carKey == car.key)
            .toList();

        trips.sort(
          (a, b) => b.endTimestamp.compareTo(a.endTimestamp),
        ); // Newest first

        if (trips.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No trips recorded yet. Tap the steering wheel to start your first drive!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: trips.length,
          shrinkWrap: true, // Important inside a SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Disables scrolling for the inner list
          itemBuilder: (context, index) {
            return _buildTripCard(trips[index]);
          },
        );
      },
    );
  }

  // Helper widget for a single trip history card
  Widget _buildTripCard(TripSession trip) {
    final date = DateFormat('MMM d, yyyy').format(trip.endTimestamp);
    final time = DateFormat('h:mm a').format(trip.endTimestamp);
    final distanceKm = (trip.distanceInMeters / 1000).toStringAsFixed(1);
    final duration = Duration(
      seconds: trip.durationInSeconds,
    ).toString().split('.').first.padLeft(8, "0");

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$date at $time',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$distanceKm km  -  $duration',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          // Display event counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Brakes: ${trip.harshBrakingCount}',
                style: TextStyle(color: Colors.red.shade400),
              ),
              Text(
                'Accels: ${trip.rapidAccelCount}',
                style: TextStyle(color: Colors.orange.shade400),
              ),
              Text(
                'Turns: ${trip.sharpTurnCount}',
                style: TextStyle(color: Colors.yellow.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
