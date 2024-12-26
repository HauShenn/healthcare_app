import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_app/services/firestore_service.dart'; // Update with your actual path

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

  @override
  void initState() {
    super.initState();
    _loadLatestAssessment();
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
          SnackBar(content: Text('Health assessment saved successfully')),
        );

        // Clear form
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assessment: $e')),
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
      appBar: AppBar(
        title: Text('Health Assessment'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _showAssessmentHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAssessmentCard(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAssessment,
                child: Text('Save Assessment'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Health Assessment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _bloodPressureController,
              decoration: InputDecoration(
                labelText: 'Blood Pressure (mmHg)',
                hintText: 'e.g., 120/80',
                prefixIcon: Icon(Icons.favorite),
              ),
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter blood pressure' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _heartRateController,
              decoration: InputDecoration(
                labelText: 'Heart Rate (bpm)',
                hintText: 'e.g., 75',
                prefixIcon: Icon(Icons.timeline),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter heart rate' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g., 70',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter weight' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _temperatureController,
              decoration: InputDecoration(
                labelText: 'Temperature (°C)',
                hintText: 'e.g., 37.0',
                prefixIcon: Icon(Icons.thermostat),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter temperature' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional observations...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  // Update the _showAssessmentHistory method to use FirestoreService
  void _showAssessmentHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assessment History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _firestoreService.getHealthAssessments(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final assessments = snapshot.data ?? [];

                    if (assessments.isEmpty) {
                      return Center(child: Text('No assessments recorded yet'));
                    }

                    return ListView.builder(
                      controller: controller,
                      itemCount: assessments.length,
                      itemBuilder: (context, index) {
                        final assessment = assessments[index];
                        final timestamp = (assessment['timestamp'] as Timestamp).toDate();

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(timestamp),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BP: ${assessment['bloodPressure']} mmHg'),
                                Text('HR: ${assessment['heartRate']} bpm'),
                                Text('Weight: ${assessment['weight']} kg'),
                                Text('Temp: ${assessment['temperature']}°C'),
                                if (assessment['notes']?.isNotEmpty ?? false)
                                  Text('Notes: ${assessment['notes']}'),
                              ],
                            ),
                            isThreeLine: true,
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