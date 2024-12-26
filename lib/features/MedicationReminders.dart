import 'package:flutter/material.dart';
import 'package:healthcare_app/services/firestore_service.dart';
import 'package:healthcare_app/services/notificationService.dart';

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

  // Constants for consistent styling
  final double fontSize = 20.0;
  final double iconSize = 32.0;
  final double spacing = 24.0;
  final double buttonHeight = 60.0;

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
        backgroundColor: Colors.blue.shade600,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Medications',
          style: TextStyle(fontSize: fontSize * 1.2),
        ),
        actions: [
          if (_editingReminderId != null)
            IconButton(
              icon: Icon(Icons.cancel, size: iconSize),
              onPressed: _clearForm,
              tooltip: 'Cancel editing',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInstructions(),
              SizedBox(height: spacing),
              _buildReminderForm(),
              SizedBox(height: spacing),
              _buildRemindersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: iconSize),
                SizedBox(width: 12),
                Text(
                  'How to Add Medication',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '1. Enter medication name\n'
                  '2. Enter dosage amount\n'
                  '3. Select reminder time\n'
                  '4. Tap "Add Reminder" button',
              style: TextStyle(
                fontSize: fontSize * 0.9,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editingReminderId != null
                    ? 'Edit Medication'
                    : 'Add New Medication',
                style: TextStyle(
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: spacing),
              _buildTextField(
                controller: _medicationController,
                label: 'Medication Name',
                icon: Icons.medication,
              ),
              SizedBox(height: spacing),
              _buildTextField(
                controller: _dosageController,
                label: 'Dosage Amount',
                icon: Icons.format_size,
              ),
              SizedBox(height: spacing),
              _buildTimeSelector(),
              SizedBox(height: spacing),
              SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _editingReminderId != null
                        ? 'Update Medication'
                        : 'Add Medication',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize * 0.9),
        prefixIcon: Icon(icon, size: iconSize * 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: spacing,
          horizontal: spacing / 2,
        ),
      ),
      validator: (value) => value?.isEmpty ?? true
          ? 'Please enter $label'
          : null,
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: spacing,
          horizontal: spacing / 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: iconSize * 0.8),
            SizedBox(width: spacing / 2),
            Text(
              'Reminder Time: ${_selectedTime.format(context)}',
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 4),
      );
    }

    if (_reminders.isEmpty) {
      return Center(
        child: Text(
          'No medications added yet',
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Medications',
          style: TextStyle(
            fontSize: fontSize * 1.1,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: spacing),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _reminders.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medication,
                            color: Colors.blue.shade600,
                            size: iconSize),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder['medication_name'],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${reminder['dosage']} at ${reminder['time']}',
                                style: TextStyle(
                                  fontSize: fontSize * 0.8,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: spacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          onTap: () => _editReminder(reminder),
                          color: Colors.blue,
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: 'Delete',
                          onTap: () async {
                            await _firestoreService
                                .deleteMedicationReminder(reminder['id']);
                            _loadReminders();
                          },
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: spacing / 2,
          horizontal: spacing,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: iconSize * 0.8),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize * 0.8,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}