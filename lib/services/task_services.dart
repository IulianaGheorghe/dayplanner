import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class Task {
  String userID;
  String title;
  String description;
  DateTime date;
  TimeOfDay? startTime;
  TimeOfDay? deadline;
  String priority;
  LatLng? destination;
  DateTime createdAt;

  Task(this.userID, this.title, this.description, this.date, this.startTime, this.deadline, this.priority, this.destination, this.createdAt);

  Future<void> addToFirestore() async {
    final firestore = FirebaseFirestore.instance;
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);

    try {
      if( title == '') {
        throw Exception('Field cannot be empty.');
      } else {
        DocumentReference documentRef = firestore.collection("users").doc(userID).collection("tasks").doc(formattedDate);
        DocumentSnapshot snapshot = await documentRef.get();
        if (snapshot.exists) {
          int currentNoOfTasks = snapshot.get('tasksCount');
          int incrementedValue = currentNoOfTasks + 1;
          await documentRef.update({'tasksCount': incrementedValue});
        } else {
          await firestore.collection("users").doc(userID).collection("tasks")
              .doc(formattedDate)
              .set({'tasksCount': 1})
              .catchError((error) => throw Exception("Failed to create document for day in tasks: $error"));
        }

        await firestore.collection("users")
            .doc(userID)
            .collection("tasks")
            .doc(formattedDate)
            .collection("day tasks")
            .add(
            {
              'title': title,
              'description': description,
              'date': Timestamp.fromDate(date),
              'startTime': (startTime == null) ? '' : "${startTime!.hour}:${startTime!.minute}",
              'deadline': (deadline == null) ? '' : "${deadline!.hour}:${deadline!.minute}",
              'priority': priority,
              'destination': (destination == null) ? '' : "${destination!.latitude},${destination!.longitude}",
              'createdAt': createdAt.toUtc(),
            }
          );
      }
    } catch (e) {
      throw Exception('Task cannot be added to firebase.');
    }
  }
}

Future<List<Task>> getTasksForDay(DateTime day, String userID) async {
  String formattedDate = DateFormat('dd-MM-yyyy').format(day);

  QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userID)
      .collection('tasks')
      .doc(formattedDate)
      .collection("day tasks")
      .get();

  List<Task> tasks = snapshot.docs.map((doc) {
    Map<String, dynamic> data = doc.data();
    return Task(
        userID,
        data['title'],
        data['description'],
        doc['date'].toDate(),
        (doc['startTime'] != '') ?
          TimeOfDay(hour: int.parse(doc['startTime'].split(':')[0]),
            minute: int.parse(doc['startTime'].split(':')[1]),
          ) : null,
        (doc['deadline'] != '') ?
          TimeOfDay(hour: int.parse(doc['deadline'].split(':')[0]),
            minute: int.parse(doc['deadline'].split(':')[1]),
          ) : null,
        doc['priority'],
        (doc['destination'] != '') ?
          LatLng(double.parse(doc['destination'].split(',')[0]),
            double.parse(doc['destination'].split(',')[1]),
          ) : null,
        (data['createdAt'] as Timestamp).toDate(),
    );
  }).toList();

  return tasks;
}
