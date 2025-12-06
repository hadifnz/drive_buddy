// lib/screens/driving_session_screen.dart

import 'dart:async';
import 'dart:math'; // Import Math for sqrt()
import 'package:flutter/material.dart';
import 'package:drive_buddy/models/car_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drive_buddy/models/trip_session_model.dart';
import 'dart:io' show Platform;

class DrivingSessionScreen extends StatefulWidget {
  final Car car;
  const DrivingSessionScreen({super.key, required this.car});

  @override
  State<DrivingSessionScreen> createState() => _DrivingSessionScreenState();
}

class _DrivingSessionScreenState extends State<DrivingSessionScreen> {
  StreamSubscription? _positionStream;
  StreamSubscription? _accelerometerStream;
  StreamSubscription? _gyroscopeStream;
  Timer? _timer;

  int _sessionDuration = 0;
  double _speedKmh = 0;
  double _distanceMeters = 0;
  Position? _lastPosition;

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
    _endSession();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (await Permission.location.request().isGranted) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _sessionDuration++);
        });

        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 5,
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
                });
              }
            });

        // --- UPGRADED SENSOR LOGIC (ORIENTATION INDEPENDENT) ---
        // We use userAccelerometerEvents (excludes gravity).
        // Magnitude = sqrt(x^2 + y^2 + z^2)
        _accelerometerStream = userAccelerometerEvents.listen((event) {
          if (!_isDetectingEvents) return;

          double magnitude = sqrt(
            (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
          );

          // Threshold: 4.0 m/s^2 is roughly 0.4g of force
          if (magnitude > 4.0) {
            // Determine if it was mostly Braking/Accel (Z-axis dominant) or Turning (X-axis dominant)
            // Note: This assumes some alignment, but magnitude captures the STRESS regardless.
            // For simplicity in this "Pocket Mode", we count high G-force as "Harsh Event".
            // To be more specific, we'd need rotation matrices, but Magnitude is sufficient for Wear Calc.

            // Simple logic: frequent spikes = Aggressive
            setState(() => _rapidAccelCount++); // We log it as an event count
            _throttleEvents();
          }

          // Legacy check if phone happens to be upright (optional, keeps old logic working too)
          if (event.z < -6.0) {
            setState(() => _harshBrakingCount++);
            _throttleEvents();
          }
        });

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

  // --- UPGRADED END SESSION LOGIC (EFFECTIVE KM) ---
  void _endSession() {
    if (_isSessionSaved) return;
    _isSessionSaved = true;

    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();

    // 1. Save Trip
    final newTrip = TripSession(
      carKey: widget.car.key,
      endTimestamp: DateTime.now(),
      durationInSeconds: _sessionDuration,
      distanceInMeters: _distanceMeters,
      harshBrakingCount: _harshBrakingCount,
      rapidAccelCount: _rapidAccelCount,
      sharpTurnCount: _sharpTurnCount,
    );
    Hive.box<TripSession>('trip_sessions').add(newTrip);

    // 2. Calculate Effective KM & Update Car
    final carBox = Hive.box<Car>('cars');
    final liveCar = carBox.get(widget.car.key);

    if (liveCar != null) {
      double actualKm = _distanceMeters / 1000.0;

      // --- PREDICTIVE MAINTENANCE FORMULA ---
      double stressFactor = 0.0;

      // A. Cold Start Penalty: Trip less than 10 mins (600s)
      if (_sessionDuration < 600) {
        stressFactor += 1.0; // +100% wear (Engine never warmed up)
      }

      // B. Aggressive Driving Penalty: High event count per km
      // If events happen frequently (e.g., > 5 events total in a short trip)
      if ((_harshBrakingCount + _rapidAccelCount + _sharpTurnCount) > 5) {
        stressFactor += 0.5; // +50% wear
      }

      double effectiveKm = actualKm * (1 + stressFactor);

      // Update Car Stats
      liveCar.currentMileage += actualKm; // Odometer shows REAL distance
      liveCar.oilLifeRemaining -=
          effectiveKm; // Oil Life degrades based on STRESS

      if (liveCar.oilLifeRemaining < 0) liveCar.oilLifeRemaining = 0;

      liveCar.save();
    }
  }

  // Helpers
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
                onPressed: () {
                  _endSession();
                  Navigator.of(context).pop();
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
