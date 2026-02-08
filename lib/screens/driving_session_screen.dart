// lib/screens/driving_session_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Standard package for GPS
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
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();
    super.dispose();
  }

  // --- HELPER: ROBUST PERMISSION CHECK ---
  Future<bool> _requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if GPS Hardware is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("GPS is disabled. Please turn it on.")));
      }
      return false;
    }

    // 2. Check App Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied.")));
        }
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Permissions are permanently denied. Check settings.")));
      }
      return false;
    } 

    return true;
  }

  Future<void> _startSession() async {
    // 1. Ensure permissions before starting
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
        
        // Start Timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _sessionDuration++);
        });

        // 2. CONFIGURE BACKGROUND TRACKING
        // We use 'final' instead of 'const' to avoid errors
        final LocationSettings locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0, // Capture ALL movement (no minimum distance)
            intervalDuration: const Duration(seconds: 2), // Update every 2 seconds
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationText: "Drive Buddy is tracking your trip...",
              notificationTitle: "Drive Buddy Active",
              enableWakeLock: true, // CRITICAL: Keeps CPU running when screen is off
            )
        );

        _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
          
          if (!mounted) return;

          // --- FIX 1: Relax Accuracy for City Driving ---
          // Urban areas (buildings) drop accuracy to 50-80m. We allow up to 100m.
          if (position.accuracy > 100) {
             // print("Skipping point: Poor accuracy (${position.accuracy})");
             return;
          }

          double newSpeed = position.speed * 3.6; // Convert m/s to km/h

          // --- FIX 2: Prevent 'Ghost' Drifting when Parked ---
          // If speed is less than 1.5 km/h, we assume the car is stopped.
          // This prevents the speedometer from jumping to "1 km/h" when stationary.
          if (newSpeed < 1.5) {
            newSpeed = 0.0;
          }

          double distIncrement = 0;
          if (_lastPosition != null) {
            distIncrement = Geolocator.distanceBetween(
              _lastPosition!.latitude, _lastPosition!.longitude,
              position.latitude, position.longitude,
            );
            
            // --- FIX 3: Ignore Tiny GPS Jitters ---
            // Only add DISTANCE if the jump is > 5 meters.
            if (distIncrement < 5) {
              distIncrement = 0;
            }
          }

          setState(() {
            _speedKmh = newSpeed;
            
            // --- FIX 4: Always Record Path ---
            // Even if distance didn't increase (stopped at light), record the point.
            // This keeps the blue line connected on the map.
            _recordedPath.add("${position.latitude},${position.longitude}");
            
            if (distIncrement > 0) {
              _distanceMeters += distIncrement;
              _lastPosition = position; 
            } else if (_lastPosition == null) {
              _lastPosition = position; // Initialize first point
            }
          });
        });

        // 3. Accelerometer (G-Force Detection)
        _accelerometerStream = userAccelerometerEvents.listen((event) {
          if (!_isDetectingEvents) return;
          
          // Only detect harsh events if we are moving faster than 10 km/h
          if (_speedKmh < 10) return; 

          double magnitude = sqrt((event.x * event.x) + (event.y * event.y) + (event.z * event.z));
          
          // Threshold > 4.0 m/s^2 for Harsh Braking/Accel
          if (magnitude > 4.0) {
            setState(() => _rapidAccelCount++); 
            _throttleEvents();
          }
        });

        // 4. Gyroscope (Sharp Turn Detection)
        _gyroscopeStream = gyroscopeEvents.listen((event) {
          if (!_isDetectingEvents) return;
          if (_speedKmh < 10) return;

          // Threshold > 2.5 rad/s for Sharp Turn
          if (event.y.abs() > 2.5) {
            setState(() => _sharpTurnCount++);
            _throttleEvents();
          }
        });
    }
  }

  // Prevent multiple events triggering in 1 second
  void _throttleEvents() {
    _isDetectingEvents = false;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _isDetectingEvents = true;
    });
  }

  Future<void> _endSession() async {
    if (_isSessionSaved) return;
    _isSessionSaved = true;

    // Stop all sensors
    _timer?.cancel();
    _positionStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Create Trip Model
      final newTrip = TripSession(
        id: '', 
        carId: widget.car.id,
        endTimestamp: DateTime.now(),
        durationInSeconds: _sessionDuration,
        distanceInMeters: _distanceMeters,
        harshBrakingCount: _harshBrakingCount,
        rapidAccelCount: _rapidAccelCount, 
        sharpTurnCount: _sharpTurnCount,
        routePath: _recordedPath,
      );

      // 2. Upload to Firestore
      await FirebaseFirestore.instance.collection('trips').add(newTrip.toMap());

      // 3. Update Car Odometer & Health
      double actualKm = _distanceMeters / 1000.0;
      double stressFactor = 0.0;
      
      // Logic: Short trips (<10 mins) or lots of events increase wear
      if (_sessionDuration < 600) stressFactor += 1.0; 
      if ((_harshBrakingCount + _rapidAccelCount + _sharpTurnCount) > 5) stressFactor += 0.5;

      double effectiveKm = actualKm * (1 + stressFactor); // "Wear" km is higher than actual km

      await FirebaseFirestore.instance.collection('cars').doc(widget.car.id).update({
        'currentMileage': FieldValue.increment(actualKm),
        'oilLifeRemaining': FieldValue.increment(-effectiveKm),
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close Dialog
        Navigator.of(context).pop(); // Go back to Dashboard
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close Dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
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
            // Speedometer
            Column(
              children: [
                Text(_speedKmh.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold)),
                const Text('km/h', style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
            
            // Duration and Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Duration', _formatDuration(_sessionDuration)),
                _buildStatCard('Distance', '${(_distanceMeters / 1000).toStringAsFixed(2)} km'),
              ],
            ),
            
            // Events
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEventCard('Harsh', _harshBrakingCount, Colors.red.shade700),
                _buildEventCard('Accel', _rapidAccelCount, Colors.orange.shade700),
                _buildEventCard('Turns', _sharpTurnCount, Colors.yellow.shade700),
              ],
            ),
            
            // End Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _endSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('End Driving', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
      ],
    );
  }

  Widget _buildEventCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
      ],
    );
  }
}