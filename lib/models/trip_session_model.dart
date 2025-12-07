import 'package:hive/hive.dart';

part 'trip_session_model.g.dart';

@HiveType(typeId: 1)
class TripSession extends HiveObject {
  @HiveField(0)
  late int carKey;

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

  // --- NEW FIELD: STORE THE ROUTE ---
  @HiveField(7)
  List<String>? routePath; // Stored as "lat,lng" strings

  TripSession({
    required this.carKey,
    required this.endTimestamp,
    required this.durationInSeconds,
    required this.distanceInMeters,
    required this.harshBrakingCount,
    required this.rapidAccelCount,
    required this.sharpTurnCount,
    this.routePath,
  });
}
