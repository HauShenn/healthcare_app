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

// Update at the top of your _MedicationReminderPageState class
  final double fontSize = 28.0;       // Increased from 20.0
  final double subtitleSize = 22.0;   // New
  final double bodySize = 20.0;       // New
  final double iconSize = 36.0;       // Increased from 32.0
  final double spacing = 24.0;
  final double buttonHeight = 72.0;   // Increased from 60.0

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
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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


  Future<void> _saveReminder() async {
    final timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      String reminderId;
      if (_editingReminderId != null) {
        reminderId = _editingReminderId!;
        await _firestoreService.updateMedicationReminder(
          id: reminderId,
          medicationName: _medicationController.text,
          dosage: _dosageController.text,
          time: timeString,
          repeat: 'daily',
        );
      } else {
        reminderId = await _firestoreService.saveMedicationReminder(
          medicationName: _medicationController.text,
          dosage: _dosageController.text,
          time: timeString,
          repeat: 'daily',
        );
      }

      // Cancel existing notification if editing
      if (_editingReminderId != null) {
        await NotificationService.cancelNotification(reminderId);
      }

      // Create or recreate the notification
      await NotificationService.createMedicationReminder(
        reminderId: reminderId,
        title: 'Medication Reminder',
        body: 'Time to take ${_medicationController.text} - ${_dosageController.text}',
        time: timeString,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingReminderId != null ? 'Reminder updated!' : 'Reminder added!')),
      );

      _clearForm();
      await _loadReminders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving reminder: ${e.toString()}')),
      );
    }
  }


  Future<void> _showAddEditDialog([Map<String, dynamic>? reminder]) {
    TimeOfDay dialogTime = reminder != null
        ? TimeOfDay(
      hour: int.parse(reminder['time'].split(':')[0]),
      minute: int.parse(reminder['time'].split(':')[1]),
    )
        : TimeOfDay.now();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(spacing),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          reminder != null ? 'Edit Medication' : 'Add New Medication',
                          style: TextStyle(
                            fontSize: fontSize,
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
                        _buildTextField(
                          controller: _dosageController,
                          label: 'Dosage Amount',
                          icon: Icons.format_size,
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: spacing),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.teal.shade100),
                          ),
                          child: InkWell(
                            onTap: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: dialogTime,
                              );
                              if (picked != null && picked != dialogTime) {
                                setState(() {
                                  dialogTime = picked;
                                });
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      size: iconSize * 0.8,
                                      color: Colors.teal.shade600,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reminder Time',
                                        style: TextStyle(
                                          fontSize: subtitleSize,
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        dialogTime.format(context),
                                        style: TextStyle(
                                          fontSize: bodySize,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearForm();
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: bodySize),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _selectedTime = dialogTime;
                                  await _saveReminder();
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing,
                                  vertical: spacing / 2,
                                ),
                              ),
                              child: Text(
                                reminder != null ? 'Update' : 'Add',
                                style: TextStyle(
                                  fontSize: bodySize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: bodySize,
          color: Colors.grey[800],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: subtitleSize,
            color: Colors.teal.shade700,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              icon,
              size: iconSize * 0.8,
              color: Colors.teal.shade600,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) => value?.isEmpty ?? true
            ? 'Please enter $label'
            : null,
      ),
    );
  }



  Widget _buildRemindersList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
        ),
      );
    }

    if (_reminders.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            children: [
              Icon(
                Icons.medication_outlined,
                size: iconSize * 2,
                color: Colors.grey[400],
              ),
              SizedBox(height: spacing),
              Text(
                'No medications added yet',
                style: TextStyle(
                  fontSize: bodySize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _reminders.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
            return _buildReminderCard(reminder);
          },
        ),
      ],
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
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
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    size: iconSize,
                    color: Colors.teal.shade600,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder['medication_name'],
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: iconSize * 0.6,
                            color: Colors.teal.shade600,
                          ),
                          SizedBox(width: 8),
                          Text(
                            reminder['time'],
                            style: TextStyle(
                              fontSize: bodySize,
                              color: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: iconSize * 0.6,
                            color: Colors.teal.shade600,
                          ),
                          SizedBox(width: 8),
                          Text(
                            reminder['dosage'],
                            style: TextStyle(
                              fontSize: bodySize,
                              color: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onTap: () => _deleteReminder(reminder),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// New method for handling deletion with confirmation
  Future<void> _deleteReminder(Map<String, dynamic> reminder) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Reminder',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this medication reminder?',
          style: TextStyle(fontSize: bodySize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: bodySize),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: bodySize,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.deleteMedicationReminder(reminder['id']);
      _loadReminders();
    }
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: spacing),
                _buildRemindersList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: Icon(Icons.add),
        label: Text('Add Medication'),
        backgroundColor: Colors.teal.shade600,
      ),
    );
  }

}


