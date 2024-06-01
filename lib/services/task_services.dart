import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class Task {
  String userID;
  String title;
  String description;
  String category;
  DateTime date;
  TimeOfDay? startTime;
  TimeOfDay? deadline;
  String priority;
  LatLng? destination;
  String status;
  DateTime createdAt;

  Task(this.userID, this.title, this.description, this.category, this.date, this.startTime, this.deadline, this.priority, this.destination, this.status, this.createdAt);

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
              .set({'date': date, 'tasksCount': 1})
              .catchError((error) => throw Exception("Failed to create document for day in tasks: $error"));
        }

        DocumentReference newTaskRef = await firestore.collection("users")
            .doc(userID)
            .collection("tasks")
            .doc(formattedDate)
            .collection("day tasks")
            .add(
            {
              'title': title,
              'description': description,
              'category': category,
              'date': Timestamp.fromDate(date),
              'startTime': (startTime == null) ? '' : "${startTime!.hour}:${startTime!.minute}",
              'deadline': (deadline == null) ? '' : "${deadline!.hour}:${deadline!.minute}",
              'priority': priority,
              'destination': (destination == null) ? '' : "${destination!.latitude},${destination!.longitude}",
              'status': status,
              'createdAt': createdAt.toUtc(),
            }
          );
        String categoryId = await getCategoryId(userID, category);
        await firestore.collection("users")
            .doc(userID)
            .collection("categories")
            .doc(categoryId)
            .collection("tasks")
            .add(
              {
                'taskRef': newTaskRef
              }
            );
      }
    } catch (e) {
      throw Exception('Task cannot be added to firebase.');
    }
  }
}

Future<String> getCategoryId(String userID, String category) async {
  String id = '';

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userID)
      .collection('categories')
      .where('name', isEqualTo: category)
      .get();

  for (var doc in snapshot.docs) {
    id = doc.id;
  }

  return id;
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
        data['category'],
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
        doc['status'],
        (data['createdAt'] as Timestamp).toDate(),
    );
  }).toList();

  return tasks;
}

Future<Map<String, int>> getTasksCountForMonth(DateTime focusedDay, String userID) async {
  DateTime firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
  DateTime lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);

  int firstDayWeekday = firstDayOfMonth.weekday;
  DateTime firstVisibleDay = firstDayOfMonth.subtract(Duration(days: firstDayWeekday - 1));
  int lastDayWeekday = lastDayOfMonth.weekday;
  DateTime lastVisibleDay = lastDayOfMonth.add(Duration(days: 7 - lastDayWeekday));

  QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userID)
      .collection('tasks')
      .where('date', isGreaterThanOrEqualTo: firstVisibleDay, isLessThanOrEqualTo: lastVisibleDay)
      .get();

  Map<String, int> tasksCount = {};
  for (var doc in snapshot.docs) {
    String taskDay = doc.id;
    tasksCount[taskDay] = doc.data()['tasksCount'];
  }

  return tasksCount;
}

Future<void> updateStatus(String userID, String task, String formattedDate, String status) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(userID)
      .collection("tasks")
      .doc(formattedDate)
      .collection("day tasks")
      .doc(task)
      .update({'status': status});
}

Future<List<Map<String, dynamic>>> getAllTasksForToday(String userID) async {
  final todayDate = DateTime.now();
  String formattedDate = DateFormat('dd-MM-yyyy').format(todayDate);
  List<Map<String, dynamic>> tasksData = [];

  final snapshot = await FirebaseFirestore.instance
      .collection("users")
      .doc(userID)
      .collection("tasks")
      .doc(formattedDate)
      .collection("day tasks")
      .get();

  if (snapshot.docs.isNotEmpty) {
    tasksData = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'title': doc['title'],
        'description': doc['description'],
        'category': doc['category'],
        'date': doc['date'].toDate(),
        'startTime': (doc['startTime'] != '')
            ? TimeOfDay(
          hour: int.parse(doc['startTime'].split(':')[0]),
          minute: int.parse(doc['startTime'].split(':')[1]),
        )
            : null,
        'deadline': (doc['deadline'] != '')
            ? TimeOfDay(
          hour: int.parse(doc['deadline'].split(':')[0]),
          minute: int.parse(doc['deadline'].split(':')[1]),
        )
            : null,
        'priority': doc['priority'],
        'destination': (doc['destination'] != '')
            ? LatLng(
          double.parse(doc['destination'].split(',')[0]),
          double.parse(doc['destination'].split(',')[1]),
        )
            : null,
        'status': doc['status'],
      };
    }).toList();
  }
  return tasksData;
}

Future<List<Map<String, dynamic>>> getTasksByCategoryForToday(String userID, String category) async {
  final todayDate = DateTime.now();
  String formattedDate = DateFormat('dd-MM-yyyy').format(todayDate);
  List<Map<String, dynamic>> tasksData = [];

  final snapshot = await FirebaseFirestore.instance
      .collection("users")
      .doc(userID)
      .collection("tasks")
      .doc(formattedDate)
      .collection("day tasks")
      .where('category', isEqualTo: category)
      .get();

  if (snapshot.docs.isNotEmpty) {
    tasksData = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'title': doc['title'],
        'description': doc['description'],
        'category': doc['category'],
        'date': doc['date'].toDate(),
        'startTime': (doc['startTime'] != '')
            ? TimeOfDay(
          hour: int.parse(doc['startTime'].split(':')[0]),
          minute: int.parse(doc['startTime'].split(':')[1]),
        )
            : null,
        'deadline': (doc['deadline'] != '')
            ? TimeOfDay(
          hour: int.parse(doc['deadline'].split(':')[0]),
          minute: int.parse(doc['deadline'].split(':')[1]),
        )
            : null,
        'priority': doc['priority'],
        'destination': (doc['destination'] != '')
            ? LatLng(
          double.parse(doc['destination'].split(',')[0]),
          double.parse(doc['destination'].split(',')[1]),
        )
            : null,
        'status': doc['status'],
      };
    }).toList();
  }
  return tasksData;
}

Future<void> addCategory(String name, String userID) async {
  await FirebaseFirestore.instance.collection('users')
      .doc(userID)
      .collection('categories')
      .add({
    'name': name,
  });
}

Future<void> addInitialCategories(String userID) async {
  await addCategory('No category', userID);
  await addCategory('Work', userID);
  await addCategory('Study', userID);
  await addCategory('Birthdays', userID);
  await addCategory('Personal', userID);
  await addCategory('Health', userID);
  await addCategory('Shopping', userID);
  await addCategory('Fitness', userID);
  await addCategory('Events', userID);
  await addCategory('Household', userID);
}

Future<List<dynamic>> getCategories(String userID) async {
  final snapshot = await FirebaseFirestore.instance.collection('users')
      .doc(userID)
      .collection('categories')
      .orderBy('name')
      .get();

  List<dynamic> categories = snapshot.docs.map((doc) {
    Map<String, dynamic> data = doc.data();
    return data['name'];
  }).toList();

  return categories;
}