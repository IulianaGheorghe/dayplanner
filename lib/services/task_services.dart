import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayplanner/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      if( title == '') {
        throw Exception('Field cannot be empty.');
      } else {
        DocumentReference documentRef = _firestore.collection("users").doc(userID).collection("tasks").doc(formattedDate);
        DocumentSnapshot snapshot = await documentRef.get();
        if (snapshot.exists) {
          int currentNoOfTasks = snapshot.get('tasksCount');
          int incrementedValue = currentNoOfTasks + 1;
          await documentRef.update({'tasksCount': incrementedValue});
        } else {
          await _firestore.collection("users").doc(userID).collection("tasks")
              .doc(formattedDate)
              .set({'date': date, 'tasksCount': 1})
              .catchError((error) => throw Exception("Failed to create document for day in tasks: $error"));
        }

        DocumentReference newTaskRef = await _firestore.collection("users")
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
        await _firestore.collection("users")
            .doc(userID)
            .collection("categories")
            .doc(categoryId)
            .collection("tasks")
            .add(
              {
                'taskRef': newTaskRef
              }
            );
        DocumentReference documentRef2 = _firestore.collection("users")
            .doc(userID)
            .collection("categories")
            .doc(categoryId);
        DocumentSnapshot snapshot2 = await documentRef2.get();
        if (snapshot2.exists) {
          int currentNoOfTasks2 = snapshot2.get('tasksCount');
          int incrementedValue2 = currentNoOfTasks2 + 1;
          await documentRef2.update({'tasksCount': incrementedValue2});
        }
      }
    } catch (e) {
      throw Exception('Task cannot be added to firebase.');
    }
  }
}

Future<void> deleteTask(String userID, String taskID, String formattedDate, String categoryName) async{
  String categoryID = await getCategoryId(userID, categoryName);
  Future<void> updateTaskCountFromTasks() async {
    DocumentReference docRef = _firestore.collection("users").doc(userID).collection("tasks").doc(formattedDate);
    DocumentSnapshot dateSnapshot = await docRef.get();
    int currentTasksCount = dateSnapshot['tasksCount'];
    int newTasksCount = currentTasksCount - 1;
    await docRef.update({'tasksCount': newTasksCount});
  }
  Future<void> updateTaskCountFromCategories() async {
    DocumentReference docRef = _firestore.collection("users").doc(userID).collection("categories").doc(categoryID);
    DocumentSnapshot categorySnapshot = await docRef.get();
    int currentTasksCount = categorySnapshot['tasksCount'];
    int newTasksCount = currentTasksCount - 1;
    await docRef.update({'tasksCount': newTasksCount});
  }
  Future<void> deleteTaskReferenceFromCategories() async {
    DocumentReference docRef = _firestore.collection("users").doc(userID).collection("categories").doc(categoryID);
    String taskRef = 'users/$userID/tasks/$formattedDate/day tasks/$taskID';
    final taskSnapshot = await docRef
        .collection('tasks')
        .where('taskRef', isEqualTo: _firestore.doc(taskRef))
        .limit(1)
        .get();

    String taskIdFromCategory = taskSnapshot.docs.first.id;
    await docRef.collection('tasks')
        .doc(taskIdFromCategory)
        .delete();
  }
  try {
    await updateTaskCountFromTasks();
    await deleteTaskReferenceFromCategories();
    await updateTaskCountFromCategories();
    await _firestore.collection("users").doc(userID)
        .collection("tasks")
        .doc(formattedDate)
        .collection("day tasks")
        .doc(taskID)
        .delete();
  } catch (e) {
    throw Exception('Error deleting task: $e');
  }
}

Future<String> getCategoryId(String userID, String category) async {
  String id = '';

  final snapshot = await _firestore
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
  String formattedDate = DateFormat('yyyy-MM-dd').format(day);

  QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
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

  QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
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
  await _firestore
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
  String formattedDate = DateFormat('yyyy-MM-dd').format(todayDate);
  List<Map<String, dynamic>> tasksData = [];

  try {
    final snapshot = await _firestore
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
  } catch (e) {
    throw Exception('Error fetching tasks for today: $e');
  }
}

Future<List<Map<String, dynamic>>> getTasksByCategoryForToday(String userID, String category) async {
  final todayDate = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(todayDate);
  List<Map<String, dynamic>> tasksData = [];

  try {
    final snapshot = await _firestore
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
  } catch (e) {
    throw Exception('Error fetching tasks by category for today: $e');
  }
}

Future<void> addCategory(String name, String userID) async {
  await _firestore.collection('users')
    .doc(userID)
    .collection('categories')
    .add({
      'name': name,
      'tasksCount': 0,
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
  try {
    final snapshot = await _firestore.collection('users')
        .doc(userID)
        .collection('categories')
        .orderBy('name')
        .get();

    List<dynamic> categories = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      return data['name'];
    }).toList();

    return categories;
  } catch (e) {
    throw Exception('Error fetching categories names: $e');
  }
}

Future<int> getTotalTasksCount(String userID) async{
  try {
    QuerySnapshot categoriesSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('categories')
        .get();

    int totalTasks = 0;
    for (var doc in categoriesSnapshot.docs) {
      totalTasks += doc['tasksCount'] as int;
    }
    return totalTasks;
  } catch (e) {
    throw Exception('Error getting total tasks count: $e');
  }
}

Future<List<Map<String, dynamic>>> getCategoryTaskPercentage(String userID) async {
  try {
    QuerySnapshot categoriesSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('categories')
        .get();

    int totalTasks = 0;
    for (var doc in categoriesSnapshot.docs) {
      totalTasks += doc['tasksCount'] as int;
    }

    List<Map<String, dynamic>> categoryTaskPercentages = [];
    int index = 0;
    for (var categoryDoc in categoriesSnapshot.docs) {
      String categoryName = categoryDoc['name'];
      int categoryTaskCount = categoryDoc['tasksCount'];
      double categoryPercentage = totalTasks > 0 ? (categoryTaskCount / totalTasks) * 100 : 0;

      categoryTaskPercentages.add({
        'index': index,
        'name': categoryName,
        'percentage': categoryPercentage,
        'color': chartColors[index],
      });
      index++;
    }
    categoryTaskPercentages.sort((a, b) => b['percentage'].compareTo(a['percentage']));
    return categoryTaskPercentages;
  } catch (e) {
    throw Exception('Error fetching category task percentages: $e');
  }
}

Future<int> getTasksCountForDay(String userID, String date) async {
  try {
    final dateSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('tasks')
        .doc(date)
        .get();

    if (dateSnapshot.exists) {
      int tasksCountForDay = dateSnapshot['tasksCount'];
      return tasksCountForDay;
    } else {
      return 0;
    }
  } catch (e) {
    throw Exception('Error fetching tasks count for day $date: $e');
  }
}

Future<Map<String, dynamic>> getNumberOfTodoAndDoneTaskForDay(String userID, String date) async {
  try {
    QuerySnapshot doneTasksSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('tasks')
        .doc(date)
        .collection('day tasks')
        .where('status', isEqualTo: 'Done')
        .get();

    int doneTasksCountForDay = doneTasksSnapshot.size;
    int totalNumberOfTasksForDay = await getTasksCountForDay(userID, date);
    int todoTasksCountForDay = totalNumberOfTasksForDay - doneTasksCountForDay;
    int weekday = DateTime.parse(date).weekday;

    return {
      'To do': todoTasksCountForDay,
      'Done': doneTasksCountForDay,
      'Day': weekday,
    };
  } catch (e) {
    throw Exception('Error fetching number of To do and Done tasks for $date: $e');
  }
}

Future<List<Map<String, dynamic>>> getNumberOfTodoAndDoneTasksForWeek(String userID, String startOfWeek, String endOfWeek) async {
  try {
    final datesSnapshot = await _firestore
        .collection('users')
        .doc(userID)
        .collection('tasks')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startOfWeek)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endOfWeek)
        .orderBy(FieldPath.documentId)
        .get();

    List<Map<String, dynamic>> noOfTodoAndDoneTasksForWeek = [];
    if (datesSnapshot.size > 0) {

      for (var date in datesSnapshot.docs) {
        Map<String, dynamic> noOfTodoAndDoneTasksForDay = await getNumberOfTodoAndDoneTaskForDay(userID, date.id);

        noOfTodoAndDoneTasksForWeek.add(noOfTodoAndDoneTasksForDay);
      }
      if (noOfTodoAndDoneTasksForWeek.length < 7) {
        for (int i = 1; i <= 7; i++) {
          if (!noOfTodoAndDoneTasksForWeek.any((map) => map['Day'] == i)) {
            noOfTodoAndDoneTasksForWeek.add({'To do': 0, 'Done': 0, 'Day': i});
          }
        }
        noOfTodoAndDoneTasksForWeek.sort((a, b) => a['Day'].compareTo(b['Day']));
      }
    } else {
      noOfTodoAndDoneTasksForWeek = List.generate(7, (index) => {'To do': 0, 'Done': 0, 'Day': index+1});
    }

    return noOfTodoAndDoneTasksForWeek;
  } catch (e) {
    throw Exception('Error fetching number of To do and Done tasks for week: $e');
  }
}
