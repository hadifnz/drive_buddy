// lib/screens/driving_session_screen.dart

import 'dart:async';
import 'dart:math'; // For sqrt() calculation
import 'dart:io' show Platform; // For Platform check

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import your models
import 'package:drive_buddy/models/car_model.dart';
import 'package:drive_buddy/models/trip_session_model.dart';

class DrivingSessionScreen extends StatefulWidget {
  final Car car;
  const DrivingSessionScreen({super.key, required this.car});

  @override
  State<DrivingSessionScreen> createState() => _DrivingSessionScreenState();
}

class _DrivingSessionScreenState extends State<DrivingSessionScreen> {
  // Stream Subscriptions
  StreamSubscription? _positionStream;
  StreamSubscription? _accelerometerStream;
  StreamSubscription? _gyroscopeStream;
  Timer? _timer;

  // Live Session Data
  int _sessionDuration = 0; // seconds
  double _speedKmh = 0;
  double _distanceMeters = 0;
  Position? _lastPosition;

  // Route Recording (New for Map)
  final List<String> _recordedPath = [];

  // Behavior Event Counters
  int _harshBrakingCount = 0;
  int _rapidAccelCount = 0;
  int _sharpTurnCount = 0;

  // Logic Flags
  bool _isDetectingEvents = true; // For throttling events
  bool _isSessionSaved = false; // To prevent double saving

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _endSession(); // Ensure session is saved if user swipes back or closes app
    super.dispose();
  }

  Future<void> _startSession() async {
    // Only run sensors on mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      // 1. Request GPS Permission
      if (await Permission.location.request().isGranted) {
        // 2. Start Timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _sessionDuration++);
          }
        });

        // 3. Start GPS Stream
        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter:
                    10, // Update every 10 meters to save battery/storage
              ),
            ).listen((Position position) {
              if (mounted) {
                setState(() {
                  _speedKmh = position.speed * 3.6; // Convert m/s to km/h

                  if (_lastPosition != null) {
                    _distanceMeters += Geolocator.distanceBetween(
                      _lastPosition!.latitude,
                      _lastPosition!.longitude,
                      position.latitude,
                      position.longitude,
                    );
                  }
                  _lastPosition = position;

                  // --- RECORD PATH FOR MAP ---
                  // Store as "lat,lng" string
                  _recordedPath.add(
                    "${position.latitude},${position.longitude}",
                  );
                });
              }
            });

        // 4. Start Accelerometer (Orientation Independent Logic)
        _accelerometerStream = userAccelerometerEvents.listen((event) {
          if (!_isDetectingEvents) return;

          // Calculate Vector Magnitude: sqrt(x^2 + y^2 + z^2)
          // This works regardless of whether phone is in pocket, cup holder, or mount.
          double magnitude = sqrt(
            (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
          );

          // Threshold: > 4.0 m/s^2 indicates significant G-Force
          if (magnitude > 4.0) {
            // Since we don't know orientation, we count high G-Force as a "Stress Event".
            // We categorize it as Accel for simplicity in this mode, or you could split logic.
            // For this implementation, we'll increment Rapid Accel for general high stress.
            setState(() => _rapidAccelCount++);
            _throttleEvents();
          }

          // Legacy support: If phone IS mounted upright, we can still detect braking specifically
          if (event.z < -6.0) {
            setState(() => _harshBrakingCount++);
            _throttleEvents();
          }
        });

        // 5. Start Gyroscope (Turns)
        _gyroscopeStream = gyroscopeEvents.listen((event) {
          if (!_isDetectingEvents) return;
          // Check rotation on Y axis (yaw)
          if (event.y.abs() > 2.5) {
            setState(() => _sharpTurnCount++);
            _throttleEvents();
          }
        });
      } else {
        // Permission denied
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  // Prevents one event from triggering multiple times in a split second
  void _throttleEvents() {
    _isDetectingEvents = false;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _isDetectingEvents = true;
    });
  }

  // --- END SESSION & SAVE DATA ---
  void _endSession() {
    // 1. Prevent Double Save
    if (_isSessionSaved) return;
    _isSessionSaved = true;

    // 2. Stop Streams
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();

    // 3. Create Trip Record
    final newTrip = TripSession(
      carKey: widget.car.key,
      endTimestamp: DateTime.now(),
      durationInSeconds: _sessionDuration,
      distanceInMeters: _distanceMeters,
      harshBrakingCount: _harshBrakingCount,
      rapidAccelCount: _rapidAccelCount,
      sharpTurnCount: _sharpTurnCount,
      routePath: _recordedPath, // <--- SAVING THE MAP ROUTE
    );

    // Save to Hive
    Hive.box<TripSession>('trip_sessions').add(newTrip);

    // 4. Update Car Health (Predictive Maintenance Logic)
    final carBox = Hive.box<Car>('cars');
    final liveCar = carBox.get(widget.car.key);

    if (liveCar != null) {
      double actualKm = _distanceMeters / 1000.0;

      // --- STRESS FACTOR CALCULATION ---
      double stressFactor = 0.0;

      // A. Cold Start Penalty: Trip less than 10 mins (600s)
      if (_sessionDuration < 600) {
        stressFactor += 1.0; // +100% wear (Engine oil didn't warm up)
      }

      // B. Aggressive Penalty: Many events
      if ((_harshBrakingCount + _rapidAccelCount + _sharpTurnCount) > 5) {
        stressFactor += 0.5; // +50% wear
      }

      // Effective KM is usually higher than Actual KM
      double effectiveKm = actualKm * (1 + stressFactor);

      // Update Car
      liveCar.currentMileage += actualKm; // Odometer is Real
      liveCar.oilLifeRemaining -= effectiveKm; // Health is Effective

      // Clamp to 0
      if (liveCar.oilLifeRemaining < 0) liveCar.oilLifeRemaining = 0;

      liveCar.save(); // Persist changes
    }
  }

  // --- UI HELPERS ---

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEventCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Driving: ${widget.car.plateNumber}'),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Prevents accidental back button press
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Speedometer Area
            Column(
              children: [
                Text(
                  _speedKmh.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'km/h',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Duration', _formatDuration(_sessionDuration)),
                _buildStatCard(
                  'Distance',
                  '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
                ),
              ],
            ),

            // Events Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEventCard(
                  'Harsh',
                  _harshBrakingCount,
                  Colors.red.shade700,
                ),
                _buildEventCard(
                  'Accel',
                  _rapidAccelCount,
                  Colors.orange.shade700,
                ),
                _buildEventCard(
                  'Turns',
                  _sharpTurnCount,
                  Colors.yellow.shade700,
                ),
              ],
            ),

            // End Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _endSession(); // Trigger save
                  Navigator.of(context).pop(); // Close screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'End Driving',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
