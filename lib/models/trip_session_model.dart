// lib/models/trip_session_model.dart

import 'package:hive/hive.dart';

part 'trip_session_model.g.dart'; // Will be generated

@HiveType(typeId: 1) // Must be a new unique ID (Car was 0)
class TripSession extends HiveObject {
  @HiveField(0)
  late int carKey; // This links the trip to a specific Car

  @HiveField(1)
  late DateTime endTimestamp;

  @HiveField(2)
  late int durationInSeconds;

  @HiveField(3)
  late double distanceInMeters;

  @HiveField(4)
  late int harshBrakingCount;

  @HiveField(5)
  late int rapidAccelCount;

  @HiveField(6)
  late int sharpTurnCount;

  TripSession({
    required this.carKey,
    required this.endTimestamp,
    required this.durationInSeconds,
    required this.distanceInMeters,
    required this.harshBrakingCount,
    required this.rapidAccelCount,
    required this.sharpTurnCount,
  });
}
