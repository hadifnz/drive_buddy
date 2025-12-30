// lib/models/trip_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TripSession {
  final String id; // Firestore Document ID
  final String carId; // Links to the Car
  final DateTime endTimestamp;
  final int durationInSeconds;
  final double distanceInMeters;
  final int harshBrakingCount;
  final int rapidAccelCount;
  final int sharpTurnCount;
  final List<String>? routePath; // GPS Coordinates "lat,lng"

  TripSession({
    required this.id,
    required this.carId,
    required this.endTimestamp,
    required this.durationInSeconds,
    required this.distanceInMeters,
    required this.harshBrakingCount,
    required this.rapidAccelCount,
    required this.sharpTurnCount,
    this.routePath,
  });

  // Factory: Create Trip from Firestore Data
  factory TripSession.fromMap(Map<String, dynamic> data, String documentId) {
    return TripSession(
      id: documentId,
      carId: data['carId'] ?? '',
      // Handle timestamp conversion from Firestore
      endTimestamp: (data['endTimestamp'] as Timestamp).toDate(),
      durationInSeconds: data['durationInSeconds'] ?? 0,
      distanceInMeters: (data['distanceInMeters'] ?? 0).toDouble(),
      harshBrakingCount: data['harshBrakingCount'] ?? 0,
      rapidAccelCount: data['rapidAccelCount'] ?? 0,
      sharpTurnCount: data['sharpTurnCount'] ?? 0,
      // Convert dynamic list to String list safely
      routePath: data['routePath'] != null
          ? List<String>.from(data['routePath'])
          : [],
    );
  }

  // Method: Convert Trip to Map for Uploading
  Map<String, dynamic> toMap() {
    return {
      'carId': carId,
      'endTimestamp': Timestamp.fromDate(endTimestamp),
      'durationInSeconds': durationInSeconds,
      'distanceInMeters': distanceInMeters,
      'harshBrakingCount': harshBrakingCount,
      'rapidAccelCount': rapidAccelCount,
      'sharpTurnCount': sharpTurnCount,
      'routePath': routePath,
    };
  }
}
