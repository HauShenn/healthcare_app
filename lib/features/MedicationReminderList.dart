import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationReminderList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(
        child: Text('Please log in to view medication reminders'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medication_reminders')
          .doc(currentUser.uid)
          .collection('reminders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No medication reminders set'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var reminderData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var documentId = snapshot.data!.docs[index].id;

            return Dismissible(
              key: Key(documentId),
              background: Container(
                color: Colors.red,
                child: Icon(Icons.delete, color: Colors.white),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 16),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                // Delete the reminder from Firestore
                FirebaseFirestore.instance
                    .collection('medication_reminders')
                    .doc(currentUser.uid)
                    .collection('reminders')
                    .doc(documentId)
                    .delete();
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    reminderData['medication_name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosage: ${reminderData['dosage']}'),
                      Text('Time: ${reminderData['time']}'),
                      Text('Frequency: ${reminderData['repeat']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Delete the reminder from Firestore
                      FirebaseFirestore.instance
                          .collection('medication_reminders')
                          .doc(currentUser.uid)
                          .collection('reminders')
                          .doc(documentId)
                          .delete();
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}