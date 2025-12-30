// lib/screens/driving_session_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart'; // NEW
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:drive_buddy/models/car_model.dart';
import 'package:drive_buddy/models/trip_session_model.dart';

class DrivingSessionScreen extends StatefulWidget {
  final Car car;
  const DrivingSessionScreen({super.key, required this.car});

  @override
  State<DrivingSessionScreen> createState() => _DrivingSessionScreenState();
}

class _DrivingSessionScreenState extends State<DrivingSessionScreen> {
  // Streams & Timers
  StreamSubscription? _positionStream;
  StreamSubscription? _accelerometerStream;
  StreamSubscription? _gyroscopeStream;
  Timer? _timer;

  // Session Data
  int _sessionDuration = 0;
  double _speedKmh = 0;
  double _distanceMeters = 0;
  Position? _lastPosition;
  final List<String> _recordedPath = [];

  // Events
  int _harshBrakingCount = 0;
  int _rapidAccelCount = 0;
  int _sharpTurnCount = 0;

  bool _isDetectingEvents = true;
  bool _isSessionSaved = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    // Safety: Try to end session if user swipes back,
    // but in cloud apps, it's safer to require explicit "End" button
    // to avoid partial uploads. We cancel streams here.
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (await Permission.location.request().isGranted) {
        // 1. Timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _sessionDuration++);
        });

        // 2. GPS Stream
        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 10,
              ),
            ).listen((Position position) {
              if (mounted) {
                setState(() {
                  _speedKmh = position.speed * 3.6;
                  if (_lastPosition != null) {
                    _distanceMeters += Geolocator.distanceBetween(
                      _lastPosition!.latitude,
                      _lastPosition!.longitude,
                      position.latitude,
                      position.longitude,
                    );
                  }
                  _lastPosition = position;
                  _recordedPath.add(
                    "${position.latitude},${position.longitude}",
                  );
                });
              }
            });

        // 3. Accelerometer (G-Force)
        _accelerometerStream = userAccelerometerEvents.listen((event) {
          if (!_isDetectingEvents) return;
          double magnitude = sqrt(
            (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
          );

          if (magnitude > 4.0) {
            setState(() => _rapidAccelCount++);
            _throttleEvents();
          }
          if (event.z < -6.0) {
            // Specific braking check if phone is upright
            setState(() => _harshBrakingCount++);
            _throttleEvents();
          }
        });

        // 4. Gyroscope (Turns)
        _gyroscopeStream = gyroscopeEvents.listen((event) {
          if (!_isDetectingEvents) return;
          if (event.y.abs() > 2.5) {
            setState(() => _sharpTurnCount++);
            _throttleEvents();
          }
        });
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  void _throttleEvents() {
    _isDetectingEvents = false;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _isDetectingEvents = true;
    });
  }

  Future<void> _endSession() async {
    if (_isSessionSaved) return;
    _isSessionSaved = true;

    // 1. Stop Recording
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Prepare Trip Data
      final newTrip = TripSession(
        id: '', // Firestore generates this
        carId: widget.car.id, // LINK TO CAR
        endTimestamp: DateTime.now(),
        durationInSeconds: _sessionDuration,
        distanceInMeters: _distanceMeters,
        harshBrakingCount: _harshBrakingCount,
        rapidAccelCount: _rapidAccelCount,
        sharpTurnCount: _sharpTurnCount,
        routePath: _recordedPath,
      );

      // 3. Upload Trip to Firestore
      await FirebaseFirestore.instance.collection('trips').add(newTrip.toMap());

      // 4. Calculate Wear & Update Car Mileage
      double actualKm = _distanceMeters / 1000.0;
      double stressFactor = 0.0;

      if (_sessionDuration < 600) stressFactor += 1.0; // Cold start
      if ((_harshBrakingCount + _rapidAccelCount + _sharpTurnCount) > 5)
        stressFactor += 0.5;

      double effectiveKm = actualKm * (1 + stressFactor);

      // 5. Update the Car Document in Firestore
      // We use FieldValue.increment to allow safe concurrent updates
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.car.id)
          .update({
            'currentMileage': FieldValue.increment(actualKm),
            'oilLifeRemaining': FieldValue.increment(-effectiveKm),
          });

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close driving screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Driving: ${widget.car.plateNumber}'),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _endSession, // Trigger Cloud Save
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'End Driving (Save to Cloud)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

  // --- UI Helpers ---
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
}
