import 'package:drive_buddy/models/car_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drive_buddy/models/trip_session_model.dart';
import 'package:intl/intl.dart';

class LogbookScreen extends StatelessWidget {
  final Car car;

  const LogbookScreen({super.key, required this.car});

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
          "This will remove the trip and rollback the mileage/oil life.",
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

    final carBox = Hive.box<Car>('cars');
    final liveCar = carBox.get(trip.carKey);
    if (liveCar != null) {
      double tripKm = trip.distanceInMeters / 1000.0;
      liveCar.currentMileage -= tripKm;
      liveCar.oilLifeRemaining += tripKm; // Give back oil life
      if (liveCar.currentMileage < 0) liveCar.currentMileage = 0;
      liveCar.save();
    }
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

            // Car Details
            ValueListenableBuilder(
              valueListenable: Hive.box<Car>(
                'cars',
              ).listenable(keys: [car.key]),
              builder: (context, Box<Car> box, _) {
                final liveCar = box.get(car.key);
                if (liveCar == null)
                  return const Text(
                    "Car data unavailable",
                    style: TextStyle(color: Colors.white),
                  );

                Color oilColor = Colors.green;
                if (liveCar.oilLifeRemaining < 3000) oilColor = Colors.orange;
                if (liveCar.oilLifeRemaining < 1000) oilColor = Colors.red;

                return Column(
                  children: [
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
                          Text(
                            "Estimated Oil Life",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (liveCar.oilLifeRemaining / 10000).clamp(
                              0.0,
                              1.0,
                            ),
                            backgroundColor: Colors.grey.shade800,
                            color: oilColor,
                            minHeight: 10,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${liveCar.oilLifeRemaining.toStringAsFixed(0)} km remaining",
                            style: TextStyle(
                              color: oilColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "(${liveCar.oilType ?? 'Standard'} Oil)",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

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

            // Trip History
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
            _buildTripHistoryList(context),
          ],
        ),
      ),
      // Centered Start Driving Button
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
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

  Widget _buildTripHistoryList(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<TripSession>('trip_sessions').listenable(),
      builder: (context, Box<TripSession> box, _) {
        final trips = box.values
            .where((trip) => trip.carKey == car.key)
            .toList();
        trips.sort((a, b) => b.endTimestamp.compareTo(a.endTimestamp));

        if (trips.isEmpty)
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No trips recorded yet.',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );

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
    final distanceKm = (trip.distanceInMeters / 1000).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteTrip(context, trip),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$distanceKm km',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
