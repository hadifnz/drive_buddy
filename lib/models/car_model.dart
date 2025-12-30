// lib/models/car_model.dart

class Car {
  final String id; // Firestore Document ID
  final String plateNumber;
  final String model;
  final String brand;
  double currentMileage;
  final String? tireSize;
  final String? engine;
  final String? lastService;
  final String? oilType;
  double oilLifeRemaining;
  final String? engineCapacity;
  final String? transmissionType;
  final String ownerId; // Links this car to a specific user

  Car({
    required this.id,
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
    required this.ownerId,
  });

  // Factory: Create Car from Firestore Map
  factory Car.fromMap(Map<String, dynamic> data, String documentId) {
    return Car(
      id: documentId,
      plateNumber: data['plateNumber'] ?? '',
      model: data['model'] ?? '',
      brand: data['brand'] ?? '',
      currentMileage: (data['currentMileage'] ?? 0).toDouble(),
      tireSize: data['tireSize'],
      engine: data['engine'],
      lastService: data['lastService'],
      oilType: data['oilType'],
      oilLifeRemaining: (data['oilLifeRemaining'] ?? 10000).toDouble(),
      engineCapacity: data['engineCapacity'],
      transmissionType: data['transmissionType'],
      ownerId: data['ownerId'] ?? '',
    );
  }

  // Method: Convert Car to Map (for Uploading)
  Map<String, dynamic> toMap() {
    return {
      'plateNumber': plateNumber,
      'model': model,
      'brand': brand,
      'currentMileage': currentMileage,
      'tireSize': tireSize,
      'engine': engine,
      'lastService': lastService,
      'oilType': oilType,
      'oilLifeRemaining': oilLifeRemaining,
      'engineCapacity': engineCapacity,
      'transmissionType': transmissionType,
      'ownerId': ownerId,
    };
  }
}
