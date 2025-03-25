import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({Key? key}) : super(key: key);

  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> with SingleTickerProviderStateMixin {
  int _steps = 0;
  int _goal = 10000;
  String? userId;
  List<Map<String, dynamic>> _weeklyData = [];
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  final double fontSize = 28.0;
  final double subtitleSize = 22.0;
  final double bodySize = 20.0;
  final double iconSize = 36.0;
  final double spacing = 24.0;
  final double cardPadding = 24.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
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
        _steps = stepData['totalSteps'] ?? 0;  // Changed from 'steps' to 'totalSteps'
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
    TextEditingController goalController = TextEditingController(
        text: _goal.toString());

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

  Widget _buildProgressRing() {
    final double progress = _steps / _goal;
    final calories = (_steps * 0.04).round();
    final distance = (_steps * 0.000762).toStringAsFixed(2); // km

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.directions_walk,
                        size: 28,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Today\'s Steps',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flag,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  onPressed: () => _setGoal(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 15,
                    backgroundColor: Colors.teal.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _steps.toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    Text(
                      'steps today',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal.shade600,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMetricChip(Icons.local_fire_department, '$calories kcal'),
                        SizedBox(width: 12),
                        _buildMetricChip(Icons.straighten, '$distance km'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMetricChip(IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 16),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(color: Colors.teal.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Daily Goal',
                  '$_goal',
                  Icons.flag,
                  Colors.teal,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Progress',
                  '${((_steps / _goal) * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: EdgeInsets.all(24),
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your step count over the past week',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (_weeklyData.length > value.toInt()) {
                          final date = DateTime.parse(_weeklyData[value.toInt()]['date']);
                          // Only show the day name if it's different from the previous day
                          if (value.toInt() == 0 ||
                              DateTime.parse(_weeklyData[value.toInt() - 1]['date']).weekday != date.weekday) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        // Round to nearest 500
                        int roundedValue = (value / 500).round() * 500;
                        return Text(
                          '${roundedValue}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
                    left: BorderSide(color: Colors.grey[300]!, width: 0.5),
                  ),
                ),
                minX: 0,
                maxX: (_weeklyData.length - 1).toDouble(),
                minY: 0,
                maxY: (_weeklyData.isNotEmpty
                    ? ((_weeklyData.map((e) => e['steps'] as num).reduce((a, b) => a > b ? a : b) / 500).ceil() * 500)
                    : 3000),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorder: BorderSide(
                      color: Colors.blue[900]!.withOpacity(0.8),
                      width: 1,
                    ),

                    tooltipRoundedRadius: 8,
                    tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} steps',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['steps'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue[600],
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue[600]!,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[400]!.withOpacity(0.2),
                          Colors.blue[200]!.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade50],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadStepData();
              await _loadWeeklyData();
            },
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildProgressRing(),
                SizedBox(height: 20),
                _buildStatsGrid(),
                SizedBox(height: 20),
                _buildWeeklyChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}