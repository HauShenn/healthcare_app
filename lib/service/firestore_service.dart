import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUserData(String name, String email) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
      });
      print('User data added to Firestore');
    }
  }

  Future<DocumentSnapshot> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await _db.collection('users').doc(user.uid).get();
    } else {
      throw Exception("User not logged in");
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String name, String email) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
      });
      print('User data updated in Firestore');
    }
  }


  // Delete user data from Firestore
  Future<void> deleteUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).delete();
      print('User data deleted from Firestore');
    }
  }


  Future<void> saveStepData(String userId, int steps, int goal, String format) async {
    try {
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Get the current date

      // Save step data with the current date as document ID
      await _db.collection('users').doc(userId).collection('stepData').doc(currentDate).set({
        'steps': steps,
        'goal': goal,
        'date': currentDate,  // Optional: Store the date as well
      });

      print('Step data saved to Firestore');
    } catch (e) {
      print('Error saving step data: $e');
    }
  }

  // Fetch the step data for a specific day
  Future<Map<String, dynamic>> getStepData(String userId) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      var docSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('stepData')
          .doc(today)
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data()!;
        return {
          'steps': data['steps'] ?? 0,
          'goal': data['goal'] ?? 10000,
          'lastRecordedDate': data['date'] ?? today,  // Ensure we return a valid date
        };
      }

      // If no data for today, return default values
      return {'steps': 0, 'goal': 10000, 'lastRecordedDate': today};
    } catch (e) {
      print('Error fetching step data: $e');
      return {'steps': 0, 'goal': 10000, 'lastRecordedDate': today};  // Return default values on error
    }
  }
  Future<List<Map<String, dynamic>>> getWeeklyStepData(String userId) async {
    DateTime today = DateTime.now();
    DateTime weekStart = today.subtract(Duration(days: 7));

    List<Map<String, dynamic>> weeklyData = [];

    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('stepData')
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(weekStart))
          .get();

      snapshot.docs.forEach((doc) {
        var data = doc.data() as Map<String, dynamic>;  // Cast to Map<String, dynamic>
        weeklyData.add({
          'date': data['date'] ?? '',  // Safe access with null checks
          'steps': data['steps'] ?? 0,  // Default to 0 if null
          'goal': data['goal'] ?? 10000,  // Default to 10000 if null
        });
      });

      return weeklyData;
    } catch (e) {
      print('Error fetching weekly step data: $e');
      return [];  // Return empty list on error
    }
  }
  Future<String> saveMedicationReminder({
    required String medicationName,
    required String dosage,
    required String time,
    required String repeat
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentReference docRef = await _db
            .collection('medication_reminders')
            .doc(user.uid)
            .collection('reminders')
            .add({
          'medication_name': medicationName,
          'dosage': dosage,
          'time': time,
          'repeat': repeat,
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
        });

        print('Medication reminder saved to Firestore');
        return docRef.id; // Return the document ID
      } catch (e) {
        print('Error saving medication reminder: $e');
        rethrow;
      }
    } else {
      throw Exception("User not logged in");
    }
  }

  // Get medication reminders for current user
  Future<List<Map<String, dynamic>>> getMedicationReminders() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await _db
            .collection('medication_reminders')
            .doc(user.uid)
            .collection('reminders')
            .where('is_active', isEqualTo: true)
            .get();

        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Include the document ID
          return data;
        }).toList();
      } catch (e) {
        print('Error retrieving medication reminders: $e');
        return [];
      }
    } else {
      throw Exception("User not logged in");
    }
  }

  // Delete medication reminder
  Future<void> deleteMedicationReminder(String reminderId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _db
            .collection('medication_reminders')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .delete();

        // Cancel the notification when deleting the reminder
        await AwesomeNotifications().cancel(reminderId.hashCode);

        print('Medication reminder deleted from Firestore and notification cancelled');
      } catch (e) {
        print('Error deleting medication reminder: $e');
        rethrow;
      }
    } else {
      throw Exception("User not logged in");
    }
  }

// Update medication reminder
  Future<void> updateMedicationReminder({
    required String id,
    required String medicationName,
    required String dosage,
    required String time,
    required String repeat,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medication_reminders')
        .doc(id)
        .update({
      'medication_name': medicationName,
      'dosage': dosage,
      'time': time,
      'repeat': repeat,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveHealthAssessment({
    required String bloodPressure,
    required String heartRate,
    required String weight,
    required String temperature,
    String? notes,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('health_assessments')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'bloodPressure': bloodPressure,
          'heartRate': heartRate,
          'weight': weight,
          'temperature': temperature,
          'notes': notes ?? '',
        });

        print('Health assessment saved to Firestore');
      } catch (e) {
        print('Error saving health assessment: $e');
        rethrow;
      }
    } else {
      throw Exception("User not logged in");
    }
  }

  // Get health assessments for current user
  Future<List<Map<String, dynamic>>> getHealthAssessments({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        Query query = _db
            .collection('users')
            .doc(user.uid)
            .collection('health_assessments')
            .orderBy('timestamp', descending: true);

        if (startDate != null) {
          query = query.where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }

        if (endDate != null) {
          query = query.where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }

        if (limit != null) {
          query = query.limit(limit);
        }

        QuerySnapshot querySnapshot = await query.get();

        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Include the document ID
          return data;
        }).toList();
      } catch (e) {
        print('Error retrieving health assessments: $e');
        return [];
      }
    } else {
      throw Exception("User not logged in");
    }
  }

  // Get latest health assessment
  Future<Map<String, dynamic>?> getLatestHealthAssessment() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await _db
            .collection('users')
            .doc(user.uid)
            .collection('health_assessments')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          Map<String, dynamic> data =
          querySnapshot.docs.first.data() as Map<String, dynamic>;
          data['id'] = querySnapshot.docs.first.id;
          return data;
        }
        return null;
      } catch (e) {
        print('Error retrieving latest health assessment: $e');
        return null;
      }
    } else {
      throw Exception("User not logged in");
    }
  }

  // Delete health assessment
  Future<void> deleteHealthAssessment(String assessmentId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('health_assessments')
            .doc(assessmentId)
            .delete();

        print('Health assessment deleted from Firestore');
      } catch (e) {
        print('Error deleting health assessment: $e');
        rethrow;
      }
    } else {
      throw Exception("User not logged in");
    }
  }

  // Update health assessment
  Future<void> updateHealthAssessment({
    required String assessmentId,
    required String bloodPressure,
    required String heartRate,
    required String weight,
    required String temperature,
    String? notes,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('health_assessments')
            .doc(assessmentId)
            .update({
          'bloodPressure': bloodPressure,
          'heartRate': heartRate,
          'weight': weight,
          'temperature': temperature,
          'notes': notes ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        });

        print('Health assessment updated in Firestore');
      } catch (e) {
        print('Error updating health assessment: $e');
        rethrow;
      }
    } else {
      throw Exception("User not logged in");
    }
  }
}

