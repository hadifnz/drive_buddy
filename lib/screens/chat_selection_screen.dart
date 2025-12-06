// lib/screens/chat_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drive_buddy/models/car_model.dart';

class ChatSelectionScreen extends StatelessWidget {
  const ChatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Select Vehicle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button if it's a tab
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Which car needs help?',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Car>('cars').listenable(),
                builder: (context, Box<Car> box, _) {
                  final cars = box.values.toList().cast<Car>();

                  if (cars.isEmpty) {
                    return const Center(
                      child: Text(
                        "No cars added yet.",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      final car = cars[index];
                      return _buildCarTile(context, car);
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

  Widget _buildCarTile(BuildContext context, Car car) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Text(
          car.plateNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${car.brand} ${car.model}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.blueAccent,
        ),
        onTap: () {
          // Navigate to Chatbot and PASS the car object
          Navigator.of(context).pushNamed('/chatbot', arguments: car);
        },
      ),
    );
  }
}
