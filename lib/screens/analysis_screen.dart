// lib/screens/analysis_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drive_buddy/models/car_model.dart';
import 'package:drive_buddy/models/trip_session_model.dart';

class AnalysisScreen extends StatefulWidget {
  final Car car;
  const AnalysisScreen({super.key, required this.car});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _selectedView = 'Weekly'; // 'Weekly' or 'Monthly'
  String _timeFilter = 'All'; // 'All', 'Day', 'Night'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Driving Analysis', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('carId', isEqualTo: widget.car.id)
            .orderBy('endTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final allTrips = docs
              .map((d) => TripSession.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();

          // 1. PROCESS DATA
          final AnalysisData data = _processData(allTrips);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- FILTERS ---
                _buildFilterTabs(),
                const SizedBox(height: 20),

                // --- CHART ---
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: _buildChartTitles(data),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildChartBars(data),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(child: Text("Total Warnings per Period", style: TextStyle(color: Colors.white54, fontSize: 12))),
                
                const SizedBox(height: 30),

                // --- SUMMARY STATS ---
                const Text("Performance Summary", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                _buildSummaryCard(
                  title: "Total Distance", 
                  value: "${(data.totalDistance / 1000).toStringAsFixed(1)} km", 
                  icon: Icons.map, 
                  color: Colors.blue
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard(title: "Harsh Brakes", value: "${data.totalBrakes}", icon: Icons.error_outline, color: Colors.red)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSummaryCard(title: "Rapid Accel", value: "${data.totalAccel}", icon: Icons.speed, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(title: "Sharp Turns", value: "${data.totalTurns}", icon: Icons.turn_right, color: Colors.yellow),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- DATA PROCESSING LOGIC ---
  AnalysisData _processData(List<TripSession> trips) {
    final now = DateTime.now();
    List<TripSession> filteredTrips = [];
    Map<int, int> chartMap = {}; // Index (Day 0-6 or Week 0-3) -> Warning Count

    // 1. Filter by Time View (Weekly vs Monthly)
    if (_selectedView == 'Weekly') {
      // Last 7 Days
      final startOfWeek = now.subtract(const Duration(days: 6)); // 6 days ago + today
      filteredTrips = trips.where((t) => t.endTimestamp.isAfter(startOfWeek)).toList();
      
      // Initialize Map (0 to 6)
      for (int i = 0; i < 7; i++) chartMap[i] = 0;

      // Group Data
      for (var t in filteredTrips) {
        if (!_passTimeFilter(t)) continue;
        // Calculate difference in days (0 = today, 6 = 6 days ago)
        final diff = now.difference(t.endTimestamp).inDays;
        if (diff >= 0 && diff < 7) {
          // We want the chart to go Left(Oldest) -> Right(Newest)
          // So index 0 should be 6 days ago. Index 6 is today.
          int chartIndex = 6 - diff; 
          chartMap[chartIndex] = (chartMap[chartIndex] ?? 0) + t.harshBrakingCount + t.rapidAccelCount + t.sharpTurnCount;
        }
      }

    } else {
      // Monthly (Last 28 Days -> 4 Weeks)
      final startOfMonth = now.subtract(const Duration(days: 28));
      filteredTrips = trips.where((t) => t.endTimestamp.isAfter(startOfMonth)).toList();

      for (int i = 0; i < 4; i++) chartMap[i] = 0;

      for (var t in filteredTrips) {
        if (!_passTimeFilter(t)) continue;
        final diff = now.difference(t.endTimestamp).inDays;
        if (diff >= 0 && diff < 28) {
          // Week 0 (Oldest), Week 3 (Newest)
          // diff 0-6 = Week 3 (This week)
          // diff 7-13 = Week 2
          // diff 14-20 = Week 1
          // diff 21-27 = Week 0
          int weekIndex = 3 - (diff ~/ 7);
          chartMap[weekIndex] = (chartMap[weekIndex] ?? 0) + t.harshBrakingCount + t.rapidAccelCount + t.sharpTurnCount;
        }
      }
    }

    // 2. Calculate Totals for Bottom Cards
    double dist = 0;
    int brakes = 0;
    int accel = 0;
    int turns = 0;

    for (var t in filteredTrips) {
      if (!_passTimeFilter(t)) continue;
      dist += t.distanceInMeters;
      brakes += t.harshBrakingCount;
      accel += t.rapidAccelCount;
      turns += t.sharpTurnCount;
    }

    return AnalysisData(chartMap, dist, brakes, accel, turns);
  }

  bool _passTimeFilter(TripSession t) {
    if (_timeFilter == 'All') return true;
    final hour = t.endTimestamp.hour;
    // Day = 6am to 7pm (19:00). Night = 7pm to 6am.
    bool isDay = hour >= 6 && hour < 19;
    if (_timeFilter == 'Day (Sunny)' && isDay) return true;
    if (_timeFilter == 'Night' && !isDay) return true;
    return false;
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFilterTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Weekly/Monthly Toggle
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              _tabBtn('Weekly', _selectedView == 'Weekly'),
              _tabBtn('Monthly', _selectedView == 'Monthly'),
            ],
          ),
        ),
        // Day/Night Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: _timeFilter,
            dropdownColor: Colors.grey.shade900,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: ['All', 'Day (Sunny)', 'Night'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _timeFilter = val!),
          ),
        )
      ],
    );
  }

  Widget _tabBtn(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _selectedView = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }

  FlTitlesData _buildChartTitles(AnalysisData data) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Remove right numbers
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            // Label Logic
            String text = '';
            if (_selectedView == 'Weekly') {
              // value 0 is 6 days ago, value 6 is Today
              DateTime date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
              text = DateFormat('E').format(date); // Mon, Tue...
            } else {
               // Monthly: Week 1, 2, 3, 4
               text = "W${value.toInt() + 1}";
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildChartBars(AnalysisData data) {
    List<BarChartGroupData> bars = [];
    int maxIndex = _selectedView == 'Weekly' ? 7 : 4;

    for (int i = 0; i < maxIndex; i++) {
      int count = data.chartMap[i] ?? 0;
      // Determine color based on severity
      Color barColor = Colors.green;
      if (count > 2) barColor = Colors.orange;
      if (count > 5) barColor = Colors.red;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: barColor,
              width: _selectedView == 'Weekly' ? 16 : 24,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: Colors.white10), // Max height bg
            ),
          ],
        ),
      );
    }
    return bars;
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper Class to hold processed data
class AnalysisData {
  final Map<int, int> chartMap;
  final double totalDistance;
  final int totalBrakes;
  final int totalAccel;
  final int totalTurns;
  AnalysisData(this.chartMap, this.totalDistance, this.totalBrakes, this.totalAccel, this.totalTurns);
}