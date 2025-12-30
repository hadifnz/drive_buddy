// lib/screens/logbook_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drive_buddy/models/car_model.dart';
import 'package:drive_buddy/models/trip_session_model.dart';
import 'package:drive_buddy/screens/session_detail_screen.dart'; // Ensure this file exists

class LogbookScreen extends StatelessWidget {
  final Car car;

  const LogbookScreen({super.key, required this.car});

  // --- DELETE LOGIC (Cloud Transaction) ---
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
          "This will remove the trip from the cloud and rollback your odometer and oil life.",
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

    try {
      // We use a TRANSACTION to ensure both the delete and the rollback happen together.
      // If one fails, they both fail.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final carRef = FirebaseFirestore.instance
            .collection('cars')
            .doc(car.id);
        final tripRef = FirebaseFirestore.instance
            .collection('trips')
            .doc(trip.id);

        // 1. Get current car data
        final carSnapshot = await transaction.get(carRef);
        if (!carSnapshot.exists) return;

        // 2. Calculate Rollback Values
        double tripKm = trip.distanceInMeters / 1000.0;

        // Re-calculate stress factor to know how much oil life to give back
        double stressFactor = 0.0;
        if (trip.durationInSeconds < 600) stressFactor += 1.0;
        if ((trip.harshBrakingCount +
                trip.rapidAccelCount +
                trip.sharpTurnCount) >
            5)
          stressFactor += 0.5;
        double effectiveKm = tripKm * (1 + stressFactor);

        // 3. Perform Updates
        // Note: FieldValue.increment is simpler, but inside a transaction we can do manual math safely
        transaction.update(carRef, {
          'currentMileage': FieldValue.increment(-tripKm),
          'oilLifeRemaining': FieldValue.increment(effectiveKm),
        });

        // 4. Delete the Trip
        transaction.delete(tripRef);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip deleted & stats rolled back.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
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
            // 1. LIVE CAR HEADER (StreamBuilder)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .doc(car.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                // Convert Cloud Data to Car Object
                final carData = snapshot.data!.data() as Map<String, dynamic>;
                final liveCar = Car.fromMap(carData, car.id);

                // Determine Health Color
                Color oilColor = Colors.green;
                if (liveCar.oilLifeRemaining < 3000) oilColor = Colors.orange;
                if (liveCar.oilLifeRemaining < 1000) oilColor = Colors.red;

                return Column(
                  children: [
                    // Plate Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 40,
                      ),
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        liveCar.plateNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Oil Health Card
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

                    // Specs Grid
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

            // 2. TRIP HISTORY (StreamBuilder)
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

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('carId', isEqualTo: car.id)
                  .orderBy(
                    'endTimestamp',
                    descending: true,
                  ) // Show newest first
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No trips recorded yet.',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final trip = TripSession.fromMap(data, docs[index].id);
                    return _buildTripCard(context, trip);
                  },
                );
              },
            ),
          ],
        ),
      ),

      // Start Driving Button
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

  Widget _buildTripCard(BuildContext context, TripSession trip) {
    final date = DateFormat('MMM d, yyyy').format(trip.endTimestamp);
    final time = DateFormat('h:mm a').format(trip.endTimestamp);
    final distanceKm = (trip.distanceInMeters / 1000).toStringAsFixed(1);

    // Alert logic
    final totalEvents =
        trip.harshBrakingCount + trip.rapidAccelCount + trip.sharpTurnCount;
    Color statusColor = Colors.green;
    if (totalEvents > 2) statusColor = Colors.orange;
    if (totalEvents > 5) statusColor = Colors.red;

    return GestureDetector(
      onTap: () {
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
          border: Border(left: BorderSide(color: statusColor, width: 4)),
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
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => _deleteTrip(context, trip),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
