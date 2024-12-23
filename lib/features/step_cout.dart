import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../service/firestore_service.dart';
import 'package:intl/intl.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({Key? key}) : super(key: key);

  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  int _steps = 0;
  int _goal = 10000;
  String? userId;
  List<Map<String, dynamic>> _weeklyData = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Refresh data every minute
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _loadStepData();
      _loadWeeklyData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    userId = currentUser.uid;
    await _loadStepData();
    await _loadWeeklyData();
  }

  Future<void> _loadStepData() async {
    try {
      var stepData = await FirestoreService().getStepData(userId!);
      setState(() {
        _steps = stepData['steps'] ?? 0;
        _goal = stepData['goal'] ?? 10000;
      });
    } catch (e) {
      print("Error loading step data: $e");
    }
  }

  Future<void> _loadWeeklyData() async {
    if (userId != null) {
      var data = await FirestoreService().getWeeklyStepData(userId!);
      setState(() {
        _weeklyData = data;
      });
    }
  }

  void _setGoal(BuildContext context) async {
    TextEditingController goalController = TextEditingController(text: _goal.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Your Step Goal'),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter step goal'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                int newGoal = int.tryParse(goalController.text) ?? _goal;
                setState(() {
                  _goal = newGoal;
                });
                if (userId != null) {
                  await FirestoreService().saveStepData(
                    userId!,
                    _steps,
                    _goal,
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Set Goal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayProgress() {
    double progress = _steps / _goal;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                icon: Icons.directions_walk,
                title: 'Steps',
                value: _steps.toString(),
                color: Colors.blue,
              ),
              _buildMetricCard(
                icon: Icons.flag,
                title: 'Goal',
                value: _goal.toString(),
                color: Colors.green,
              ),
              _buildMetricCard(
                icon: Icons.trending_up,
                title: 'Progress',
                value: '${(progress * 100).toStringAsFixed(1)}%',
                color: Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              minHeight: 15,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _goal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: EdgeInsets.all(8),
                    tooltipMargin: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} steps',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (_weeklyData.length > value.toInt()) {
                          return Text(
                            DateFormat('E').format(
                              DateTime.parse(_weeklyData[value.toInt()]['date']),
                            ),
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      interval: _goal / 5,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['steps'].toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step Tracker'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStepData();
          await _loadWeeklyData();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildTodayProgress(),
            SizedBox(height: 20),
            _buildWeeklyChart(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _setGoal(context),
              child: Text('Set New Goal'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}