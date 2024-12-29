import 'package:flutter/material.dart';

class UserManualPage extends StatelessWidget {
  // Constants for consistent styling
  final double headerFontSize = 28.0;
  final double titleFontSize = 24.0;
  final double contentFontSize = 20.0;
  final double iconSize = 32.0;
  final double spacing = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'How to Use Your App',
          style: TextStyle(fontSize: headerFontSize),
        ),
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              SizedBox(height: spacing),
              _buildEmergencyCard(),
              SizedBox(height: spacing),
              _buildMainFeaturesGuide(),
              SizedBox(height: spacing),
              _buildDailyRoutineGuide(),
              SizedBox(height: spacing),
              _buildHelpSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  size: iconSize,
                  color: Colors.amber,
                ),
                SizedBox(width: 12),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            Text(
              'This app helps you stay healthy by:',
              style: TextStyle(
                fontSize: contentFontSize,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: spacing / 2),
            _buildBulletPoint('Reminding you to take medicines'),
            _buildBulletPoint('Counting your daily steps'),
            _buildBulletPoint('Recording your health information'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  size: iconSize,
                  color: Colors.red,
                ),
                SizedBox(width: 12),
                Text(
                  'In Case of Emergency',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            Text(
              'If you need immediate medical help:',
              style: TextStyle(
                fontSize: contentFontSize,
                color: Colors.red.shade900,
              ),
            ),
            SizedBox(height: spacing / 2),
            _buildEmergencyPoint('Call 995 for an ambulance'),
            _buildEmergencyPoint('Contact your family member'),
            _buildEmergencyPoint('Press your emergency pendant if you have one'),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFeaturesGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Features',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: spacing),
        _buildFeatureCard(
          icon: Icons.medication,
          title: 'Medicine Reminders',
          color: Colors.green.shade100,
          iconColor: Colors.green,
          steps: [
            'Tap "Meds" at the bottom of screen',
            'Press the green "Add" button',
            'Type your medicine name',
            'Choose when to take it',
            'The app will remind you when it\'s time'
          ],
        ),
        SizedBox(height: spacing / 2),
        _buildFeatureCard(
          icon: Icons.directions_walk,
          title: 'Step Counter',
          color: Colors.orange.shade100,
          iconColor: Colors.orange,
          steps: [
            'Tap "Steps" at the bottom',
            'Your daily steps will show here',
            'To set a goal, press "Set New Goal"',
            'Try to reach your daily step goal'
          ],
        ),
        SizedBox(height: spacing / 2),
        _buildFeatureCard(
          icon: Icons.health_and_safety,
          title: 'Health Records',
          color: Colors.blue.shade100,
          iconColor: Colors.blue,
          steps: [
            'Tap "Health" at the bottom',
            'Enter your blood pressure',
            'Record your weight',
            'Add any health notes',
            'Save to keep track of your health'
          ],
        ),
      ],
    );
  }

  Widget _buildDailyRoutineGuide() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: iconSize,
                  color: Colors.purple,
                ),
                SizedBox(width: 12),
                Text(
                  'Daily Routine',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            _buildRoutineStep(
              time: 'Morning:',
              tasks: [
                'Check medicine reminders',
                'Record your blood pressure',
                'Take morning walk'
              ],
            ),
            SizedBox(height: spacing / 2),
            _buildRoutineStep(
              time: 'Evening:',
              tasks: [
                'Check steps for the day',
                'Record your weight',
                'Check tomorrow\'s medicines'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: iconSize,
                  color: Colors.teal,
                ),
                SizedBox(width: 12),
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            Text(
              'If you need help using the app:',
              style: TextStyle(
                fontSize: contentFontSize,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: spacing / 2),
            _buildHelpPoint('Ask a family member to help you'),
            _buildHelpPoint('Look at this guide again anytime'),
            _buildHelpPoint('Take your time to learn each feature'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required List<String> steps,
  }) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: iconSize, color: iconColor),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            ...steps.map((step) => _buildBulletPoint(step)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              fontSize: contentFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: contentFontSize,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyPoint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_right,
              size: iconSize,
              color: Colors.red.shade900
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: contentFontSize,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineStep({
    required String time,
    required List<String> tasks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: contentFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        SizedBox(height: 8),
        ...tasks.map((task) => _buildBulletPoint(task)).toList(),
      ],
    );
  }

  Widget _buildHelpPoint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: iconSize * 0.8,
            color: Colors.teal,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: contentFontSize,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}