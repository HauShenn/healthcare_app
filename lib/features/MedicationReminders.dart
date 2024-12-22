import 'package:flutter/material.dart';
import 'package:healthcare_app/service/firestore_service.dart';
import 'package:healthcare_app/service/notificationService.dart';

class MedicationReminderPage extends StatefulWidget {
  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  String? _editingReminderId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminders();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.initializeNotification();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final reminders = await _firestoreService.getMedicationReminders();
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reminders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _clearForm() {
    _medicationController.clear();
    _dosageController.clear();
    setState(() {
      _editingReminderId = null;
      _selectedTime = TimeOfDay.now();
    });
  }

  void _editReminder(Map<String, dynamic> reminder) {
    _medicationController.text = reminder['medication_name'];
    _dosageController.text = reminder['dosage'];
    final timeComponents = reminder['time'].split(':');
    setState(() {
      _selectedTime = TimeOfDay(
        hour: int.parse(timeComponents[0]),
        minute: int.parse(timeComponents[1]),
      );
      _editingReminderId = reminder['id'];
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      if (_editingReminderId != null) {
        // Update existing reminder
        await _firestoreService.updateMedicationReminder(
          id: _editingReminderId!,
          medicationName: _medicationController.text,
          dosage: _dosageController.text,
          time: timeString,
          repeat: 'daily',
        );
      } else {
        // Add new reminder
        await _firestoreService.saveMedicationReminder(
          medicationName: _medicationController.text,
          dosage: _dosageController.text,
          time: timeString,
          repeat: 'daily',
        );
      }

      // Create or update notification
      await NotificationService.createMedicationReminder(
        title: 'Medication Reminder',
        body: 'Time to take ${_medicationController.text} - ${_dosageController.text}',
        time: timeString,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingReminderId != null ? 'Reminder updated!' : 'Reminder added!')),
      );

      _clearForm();
      _loadReminders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving reminder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medication Reminders'),
        actions: [
          if (_editingReminderId != null)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: _clearForm,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _medicationController,
                    decoration: InputDecoration(labelText: 'Medication Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _dosageController,
                    decoration: InputDecoration(labelText: 'Dosage'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  ListTile(
                    title: Text('Time: ${_selectedTime.format(context)}'),
                    trailing: Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                  ),
                  ElevatedButton(
                    onPressed: _saveReminder,
                    child: Text(_editingReminderId != null ? 'Update Reminder' : 'Add Reminder'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return Card(
                    child: ListTile(
                      title: Text(reminder['medication_name']),
                      subtitle: Text('${reminder['dosage']} at ${reminder['time']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editReminder(reminder),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await _firestoreService.deleteMedicationReminder(reminder['id']);
                              _loadReminders();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}