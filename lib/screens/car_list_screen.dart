// lib/screens/car_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drive_buddy/models/car_model.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check
    if (user == null) {
      return const Center(
        child: Text(
          "Please login to see cars",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      // 1. LISTEN TO FIREBASE
      stream: FirebaseFirestore.instance
          .collection('cars')
          .where('ownerId', isEqualTo: user.uid) // Only show MY cars
          .snapshots(),

      builder: (context, snapshot) {
        // Error State
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading data",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Empty State
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 80,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No cars found in Cloud.\nTap + to add one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // List State
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            // Convert Firestore JSON -> Car Object
            final data = docs[index].data() as Map<String, dynamic>;
            final car = Car.fromMap(data, docs[index].id);

            return _buildCarCard(context, car);
          },
        );
      },
    );
  }

  Widget _buildCarCard(BuildContext context, Car car) {
    Color statusColor = Colors.green;
    if (car.oilLifeRemaining < 3000) statusColor = Colors.orange;
    if (car.oilLifeRemaining < 1000) statusColor = Colors.red;

    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/logbook', arguments: car);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.plateNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${car.brand} ${car.model}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
