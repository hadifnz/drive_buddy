import 'package:hive/hive.dart';

part 'car_model.g.dart';

@HiveType(typeId: 0)
class Car extends HiveObject {
  @HiveField(0)
  late String plateNumber;

  @HiveField(1)
  late String model;

  @HiveField(2)
  late String brand;

  @HiveField(3)
  late double currentMileage;

  @HiveField(4)
  String? tireSize;

  @HiveField(5)
  String? engine; // Engine Code

  @HiveField(6)
  String? lastService;

  // --- NEW FIELDS ---
  @HiveField(7)
  String? oilType; // "Mineral", "Semi", "Fully"

  @HiveField(8)
  late double oilLifeRemaining;

  @HiveField(9)
  String? engineCapacity; // e.g. "1.5L"

  @HiveField(10)
  String? transmissionType; // "Auto", "Manual", "CVT"

  Car({
    required this.plateNumber,
    required this.model,
    required this.brand,
    required this.currentMileage,
    this.tireSize,
    this.engine,
    this.lastService,
    this.oilType,
    this.oilLifeRemaining = 10000.0,
    this.engineCapacity,
    this.transmissionType,
  });
}
