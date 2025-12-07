// lib/screens/logbook_screen.dart

import 'package:drive_buddy/models/car_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drive_buddy/models/trip_session_model.dart';
import 'package:drive_buddy/screens/session_detail_screen.dart'; // Import for Map Screen
import 'package:intl/intl.dart';

class LogbookScreen extends StatelessWidget {
  final Car car;

  const LogbookScreen({super.key, required this.car});

  // --- DELETE LOGIC WITH ROLLBACK ---
  Future<void> _deleteTrip(BuildContext context, TripSession trip) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          "Delete Trip?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This will remove the trip record and rollback your odometer and oil life. This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // 1. Rollback Car Stats
    final carBox = Hive.box<Car>('cars');
    final liveCar = carBox.get(trip.carKey);

    if (liveCar != null) {
      double tripKm = trip.distanceInMeters / 1000.0;

      // Subtract mileage (it never happened)
      liveCar.currentMileage -= tripKm;
      // Add back oil life (we are undoing the wear)
      liveCar.oilLifeRemaining += tripKm;

      // Safety clamps
      if (liveCar.currentMileage < 0) liveCar.currentMileage = 0;

      liveCar.save(); // Persist changes
    }

    // 2. Delete Trip
    await trip.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'LOG BOOK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Plate Number Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                car.plateNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Live Car Details
            ValueListenableBuilder(
              valueListenable: Hive.box<Car>(
                'cars',
              ).listenable(keys: [car.key]),
              builder: (context, Box<Car> box, _) {
                final liveCar = box.get(car.key);

                if (liveCar == null) {
                  return const Text(
                    "Car data unavailable",
                    style: TextStyle(color: Colors.white),
                  );
                }

                // Determine Health Color
                Color oilColor = Colors.green;
                if (liveCar.oilLifeRemaining < 3000) oilColor = Colors.orange;
                if (liveCar.oilLifeRemaining < 1000) oilColor = Colors.red;

                return Column(
                  children: [
                    // --- OIL LIFE CARD ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: oilColor.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Oil Health",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "${liveCar.oilType ?? 'Standard'} Oil",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            // Normalize assuming 10k max for visualization
                            value: (liveCar.oilLifeRemaining / 10000).clamp(
                              0.0,
                              1.0,
                            ),
                            backgroundColor: Colors.grey.shade800,
                            color: oilColor,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${liveCar.oilLifeRemaining.toStringAsFixed(0)} km remaining",
                            style: TextStyle(
                              color: oilColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- SPECS GRID ---
                    _buildDetailRow('Model', liveCar.model),
                    _buildDetailRow('Make', liveCar.brand),
                    _buildDetailRow(
                      'Capacity',
                      liveCar.engineCapacity ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Trans.',
                      liveCar.transmissionType ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Odometer',
                      '${liveCar.currentMileage.toStringAsFixed(1)} km',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // 3. Dynamic Warnings (Only show if issues detected)
            ValueListenableBuilder(
              valueListenable: Hive.box<TripSession>(
                'trip_sessions',
              ).listenable(),
              builder: (context, Box<TripSession> box, _) {
                final trips = box.values
                    .where((t) => t.carKey == car.key)
                    .toList();

                int harshBrakes = 0;
                int sharpTurns = 0;
                for (var t in trips) {
                  harshBrakes += t.harshBrakingCount;
                  sharpTurns += t.sharpTurnCount;
                }

                if (harshBrakes == 0 && sharpTurns == 0)
                  return const SizedBox.shrink();

                return Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Risk Assessment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (harshBrakes > 0)
                      _buildReminderCard(
                        'High Brake Wear Detected ($harshBrakes events)',
                        Colors.yellow.shade700,
                      ),
                    if (sharpTurns > 0)
                      _buildReminderCard(
                        'Suspension Stress Detected ($sharpTurns events)',
                        Colors.red.shade700,
                      ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),

            // 4. Trip History List
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
            const SizedBox(height: 10),
            _buildTripHistoryList(context),
          ],
        ),
      ),

      // 5. Start Driving Button
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        height: 100,
        child: Center(
          child: SizedBox(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed('/driving_session', arguments: car);
              },
              backgroundColor: Colors.grey.shade800,
              shape: const CircleBorder(),
              child: const Icon(Icons.drive_eta, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Transparent background
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistoryList(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<TripSession>('trip_sessions').listenable(),
      builder: (context, Box<TripSession> box, _) {
        final trips = box.values
            .where((trip) => trip.carKey == car.key)
            .toList();

        // Sort: Newest first
        trips.sort((a, b) => b.endTimestamp.compareTo(a.endTimestamp));

        if (trips.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No trips recorded yet.',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: trips.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildTripCard(context, trips[index]);
          },
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, TripSession trip) {
    final date = DateFormat('MMM d, yyyy').format(trip.endTimestamp);
    final time = DateFormat('h:mm a').format(trip.endTimestamp);
    final distanceKm = (trip.distanceInMeters / 1000).toStringAsFixed(1);

    // Total 'Bad' Events
    final totalEvents =
        trip.harshBrakingCount + trip.rapidAccelCount + trip.sharpTurnCount;
    Color statusColor = Colors.green;
    if (totalEvents > 2) statusColor = Colors.orange;
    if (totalEvents > 5) statusColor = Colors.red;

    return GestureDetector(
      onTap: () {
        // Navigate to the Map Analysis Screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SessionDetailScreen(trip: trip)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
          ), // Status Indicator
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$date  •  $time",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => _deleteTrip(context, trip),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(), // Removes default padding
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.map, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  "$distanceKm km",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 16),
                if (totalEvents > 0) ...[
                  Icon(Icons.warning, color: statusColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "$totalEvents alerts",
                    style: TextStyle(color: statusColor),
                  ),
                ] else
                  const Text(
                    "Clean Drive",
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),

                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
