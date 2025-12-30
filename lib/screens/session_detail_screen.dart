// lib/screens/session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:drive_buddy/models/trip_session_model.dart';

class SessionDetailScreen extends StatelessWidget {
  final TripSession trip;

  const SessionDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    // 1. Convert "lat,lng" strings back to LatLng objects
    // Note: routePath is now nullable List<String>?, so we handle it safely
    final List<LatLng> routePoints =
        trip.routePath?.map((point) {
          final split = point.split(',');
          return LatLng(double.parse(split[0]), double.parse(split[1]));
        }).toList() ??
        [];

    // Calculate center
    final center = routePoints.isNotEmpty
        ? routePoints[routePoints.length ~/ 2]
        : const LatLng(3.140853, 101.693207);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Session Analysis',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Map
          SizedBox(
            height: 350,
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.drive_buddy',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
                if (routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: routePoints.first,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                      Marker(
                        point: routePoints.last,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Stats
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trip Summary",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBigStat(
                        "Distance",
                        "${(trip.distanceInMeters / 1000).toStringAsFixed(2)} km",
                      ),
                      _buildBigStat(
                        "Duration",
                        _formatDuration(trip.durationInSeconds),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey, height: 40),
                  const Text(
                    "Harsh Event Detection",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEventCard(
                        "Harsh\nBraking",
                        trip.harshBrakingCount,
                        Colors.red,
                      ),
                      _buildEventCard(
                        "Rapid\nAccel",
                        trip.rapidAccelCount,
                        Colors.orange,
                      ),
                      _buildEventCard(
                        "Sharp\nTurns",
                        trip.sharpTurnCount,
                        Colors.yellow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
  }

  Widget _buildBigStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(String label, int count, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: count > 0 ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
