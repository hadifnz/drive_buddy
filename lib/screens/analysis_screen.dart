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
    Map<int, int> chartMap = {}; 

    if (_selectedView == 'Weekly') {
      final startOfWeek = now.subtract(const Duration(days: 6));
      filteredTrips = trips.where((t) => t.endTimestamp.isAfter(startOfWeek)).toList();
      for (int i = 0; i < 7; i++) chartMap[i] = 0;

      for (var t in filteredTrips) {
        if (!_passTimeFilter(t)) continue;
        final diff = now.difference(t.endTimestamp).inDays;
        if (diff >= 0 && diff < 7) {
          int chartIndex = 6 - diff; 
          chartMap[chartIndex] = (chartMap[chartIndex] ?? 0) + t.harshBrakingCount + t.rapidAccelCount + t.sharpTurnCount;
        }
      }
    } else {
      final startOfMonth = now.subtract(const Duration(days: 28));
      filteredTrips = trips.where((t) => t.endTimestamp.isAfter(startOfMonth)).toList();
      for (int i = 0; i < 4; i++) chartMap[i] = 0;

      for (var t in filteredTrips) {
        if (!_passTimeFilter(t)) continue;
        final diff = now.difference(t.endTimestamp).inDays;
        if (diff >= 0 && diff < 28) {
          int weekIndex = 3 - (diff ~/ 7);
          chartMap[weekIndex] = (chartMap[weekIndex] ?? 0) + t.harshBrakingCount + t.rapidAccelCount + t.sharpTurnCount;
        }
      }
    }

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
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              _tabBtn('Weekly', _selectedView == 'Weekly'),
              _tabBtn('Monthly', _selectedView == 'Monthly'),
            ],
          ),
        ),
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
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            String text = '';
            if (_selectedView == 'Weekly') {
              DateTime date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
              text = DateFormat('E').format(date); 
            } else {
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
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: Colors.white10), 
            ),
          ],
        ),
      );
    }
    return bars;
  }

  // --- FIXED SUMMARY CARD TO PREVENT OVERFLOW ---
  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      // Reduced padding from 16 to 12 to fit small screens
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          // Reduced width from 16 to 12
          const SizedBox(width: 12),
          // Wrapped in Expanded so text doesn't push out of bounds
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value, 
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis, // Add ellipsis if number is too huge
                ),
                Text(
                  title, 
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisData {
  final Map<int, int> chartMap;
  final double totalDistance;
  final int totalBrakes;
  final int totalAccel;
  final int totalTurns;
  AnalysisData(this.chartMap, this.totalDistance, this.totalBrakes, this.totalAccel, this.totalTurns);
}