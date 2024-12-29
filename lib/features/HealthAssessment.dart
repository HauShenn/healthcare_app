import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_app/services/firestore_service.dart';

class HealthAssessmentPage extends StatefulWidget {
  @override
  _HealthAssessmentPageState createState() => _HealthAssessmentPageState();
}

class _HealthAssessmentPageState extends State<HealthAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _weightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  // Constants for consistent styling
  final double fontSize = 28.0;
  final double subtitleSize = 22.0;
  final double bodySize = 20.0;
  final double iconSize = 36.0;
  final double spacing = 24.0;

  @override
  void initState() {
    super.initState();
    _loadLatestAssessment();
  }

  @override
  void dispose() {
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestAssessment() async {
    try {
      final latestAssessment = await _firestoreService.getLatestHealthAssessment();
      if (latestAssessment != null) {
        setState(() {
          _bloodPressureController.text = latestAssessment['bloodPressure'];
          _heartRateController.text = latestAssessment['heartRate'];
          _weightController.text = latestAssessment['weight'];
          _temperatureController.text = latestAssessment['temperature'];
          _notesController.text = latestAssessment['notes'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading latest assessment: $e');
    }
  }

  Future<void> _saveAssessment() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestoreService.saveHealthAssessment(
          bloodPressure: _bloodPressureController.text,
          heartRate: _heartRateController.text,
          weight: _weightController.text,
          temperature: _temperatureController.text,
          notes: _notesController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Health assessment saved successfully',
              style: TextStyle(fontSize: bodySize),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );

        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving assessment: $e',
              style: TextStyle(fontSize: bodySize),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _bloodPressureController.clear();
    _heartRateController.clear();
    _weightController.clear();
    _temperatureController.clear();
    _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[700]!, Colors.teal[50]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAssessmentCard(),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isMultiline = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiline ? 3 : 1,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: bodySize,
          color: Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontSize: subtitleSize,
            color: Colors.blue.shade700,
          ),
          hintStyle: TextStyle(
            fontSize: bodySize,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              icon,
              size: iconSize * 0.8,
              color: Colors.blue.shade600,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) =>
        value?.isEmpty ?? true ? 'Please enter ${label.toLowerCase()}' : null,
      ),
    );
  }

  Widget _buildAssessmentCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        Icons.health_and_safety,
                        size: iconSize,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Daily\nHealth\nCheck',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.history,
                    size: iconSize * 0.8,
                    color: Colors.teal.shade600,
                  ),
                  onPressed: _showAssessmentHistory,
                  tooltip: 'View History',
                ),
              ],
            ),
            SizedBox(height: spacing),
            _buildInputField(
              controller: _bloodPressureController,
              label: 'Blood Pressure',
              hint: 'e.g., 120/80 mmHg',
              icon: Icons.favorite,
              keyboardType: TextInputType.number,
            ),
            _buildInputField(
              controller: _heartRateController,
              label: 'Heart Rate',
              hint: 'e.g., 75 bpm',
              icon: Icons.timeline,
              keyboardType: TextInputType.number,
            ),
            _buildInputField(
              controller: _weightController,
              label: 'Weight',
              hint: 'e.g., 70 kg',
              icon: Icons.monitor_weight,
              keyboardType: TextInputType.number,
            ),
            _buildInputField(
              controller: _temperatureController,
              label: 'Temperature',
              hint: 'e.g., 37.0°C',
              icon: Icons.thermostat,
              keyboardType: TextInputType.number,
            ),
            _buildInputField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Any additional observations...',
              icon: Icons.note,
              isMultiline: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 72,
      margin: EdgeInsets.symmetric(vertical: spacing),
      child: ElevatedButton(
        onPressed: _saveAssessment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save, size: iconSize),
              SizedBox(width: 12),
              Text(
                'Save Health Check',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHistoryItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: iconSize * 0.7, color: color),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: bodySize,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: bodySize,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssessmentHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (_, controller) =>
                Container(
                  padding: EdgeInsets.all(spacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: iconSize,
                            color: Colors.blue.shade800,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Assessment History',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: iconSize * 0.8),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _firestoreService.getHealthAssessments(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(
                                    fontSize: bodySize,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.blue.shade600),
                                ),
                              );
                            }

                            final assessments = snapshot.data ?? [];

                            if (assessments.isEmpty) {
                              return Center(
                                child: Text(
                                  'No assessments recorded yet',
                                  style: TextStyle(
                                    fontSize: bodySize,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: controller,
                              itemCount: assessments.length,
                              itemBuilder: (context, index) {
                                final assessment = assessments[index];
                                final timestamp = (assessment['timestamp'] as Timestamp)
                                    .toDate();

                                return Card(
                                  margin: EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy HH:mm')
                                              .format(timestamp),
                                          style: TextStyle(
                                            fontSize: subtitleSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        _buildHistoryItem(
                                          Icons.favorite,
                                          'Blood Pressure',
                                          '${assessment['bloodPressure']} mmHg',
                                          Colors.red.shade400,
                                        ),
                                        _buildHistoryItem(
                                          Icons.timeline,
                                          'Heart Rate',
                                          '${assessment['heartRate']} bpm',
                                          Colors.orange.shade400,
                                        ),
                                        _buildHistoryItem(
                                          Icons.monitor_weight,
                                          'Weight',
                                          '${assessment['weight']} kg',
                                          Colors.green.shade400,
                                        ),
                                        _buildHistoryItem(
                                          Icons.thermostat,
                                          'Temperature',
                                          '${assessment['temperature']}°C',
                                          Colors.blue.shade400,
                                        ),
                                        if (assessment['notes']?.isNotEmpty ??
                                            false) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            'Notes:',
                                            style: TextStyle(
                                              fontSize: bodySize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            assessment['notes'],
                                            style: TextStyle(
                                              fontSize: bodySize,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );

  }
  }