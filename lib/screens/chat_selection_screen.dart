// lib/screens/chat_selection_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drive_buddy/models/car_model.dart';

class ChatSelectionScreen extends StatelessWidget {
  const ChatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please Login"));

    return Scaffold(
      backgroundColor: Colors.black,
      // We don't need an AppBar here if it's a tab,
      // but if it's standalone, keep it.
      // Assuming it's a tab in Dashboard, we just return the body content.
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Select a car to chat with AI mechanic",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .where('ownerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No cars found.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final car = Car.fromMap(data, docs[index].id);

                    return _buildCarTile(context, car);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarTile(BuildContext context, Car car) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(Icons.smart_toy, color: Colors.blueAccent),
        ),
        title: Text(
          car.plateNumber,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "${car.brand} ${car.model}",
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white24,
        ),
        onTap: () {
          // Navigate to Chatbot with this Car
          Navigator.of(context).pushNamed('/chatbot', arguments: car);
        },
      ),
    );
  }
}
