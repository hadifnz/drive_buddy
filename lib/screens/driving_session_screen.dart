// lib/screens/driving_session_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drive_buddy/models/car_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  // Session Data
  int _sessionDuration = 0; // in seconds
  double _speedKmh = 0;
  double _distanceMeters = 0;
  Position? _lastPosition;

  // Behavior Counters
  int _harshBrakingCount = 0;
  int _rapidAccelCount = 0;
  int _sharpTurnCount = 0;

  bool _isDetectingEvents = true; // To throttle event detection

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _endSession(); // Ensure all streams are cancelled
    super.dispose();
  }

  Future<void> _startSession() async {
    // 1. Request Permission
    if (await Permission.location.request().isGranted) {
      // 2. Start Timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _sessionDuration++;
        });
      });

      // 3. Start GPS Stream
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5, // Update every 5 meters
            ),
          ).listen((Position position) {
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
            });
          });

      // 4. Start Accelerometer Stream
      // We use userAccelerometerEvents to exclude gravity
      _accelerometerStream = userAccelerometerEvents.listen((event) {
        if (!_isDetectingEvents) return;

        // Assuming phone is in a portrait cradle (Z-axis is forward/backward)
        double z = event.z;

        // Rapid Acceleration [cite: 725]
        if (z > 4.0) {
          setState(() {
            _rapidAccelCount++;
          });
          _throttleEvents();
        }
        // Harsh Braking [cite: 724]
        else if (z < -6.0) {
          setState(() {
            _harshBrakingCount++;
          });
          _throttleEvents();
        }
      });

      // 5. Start Gyroscope Stream [cite: 720]
      _gyroscopeStream = gyroscopeEvents.listen((event) {
        if (!_isDetectingEvents) return;

        // Assuming phone is in a portrait cradle (Y-axis is yaw/turning)
        double y = event.y;

        // Sudden Turn [cite: 726]
        if (y.abs() > 2.5) {
          setState(() {
            _sharpTurnCount++;
          });
          _throttleEvents();
        }
      });
    } else {
      // Handle permission denied
      Navigator.of(context).pop();
    }
  }

  // Prevents multiple events from firing in one maneuver
  void _throttleEvents() {
    _isDetectingEvents = false;
    Future.delayed(const Duration(seconds: 3), () {
      _isDetectingEvents = true;
    });
  }

  void _endSession() {
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();

    // TODO: Save the session data (duration, distance, event counts)
    // to a new HiveBox (e.g., 'trip_sessions') linked to the car.
  }

  // Helper to format duration
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Driving: ${widget.car.plateNumber}'),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Live Stats Grid
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

            // Event Counters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEventCard(
                  'Harsh Brakes',
                  _harshBrakingCount,
                  Colors.red.shade700,
                ),
                _buildEventCard(
                  'Fast Accels',
                  _rapidAccelCount,
                  Colors.orange.shade700,
                ),
                _buildEventCard(
                  'Sharp Turns',
                  _sharpTurnCount,
                  Colors.yellow.shade700,
                ),
              ],
            ),

            // End Driving Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _endSession();
                  Navigator.of(context).pop(); // Go back to Logbook
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
}
