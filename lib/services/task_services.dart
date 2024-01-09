import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Task {
  String userID;
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  LatLng destination;
  DateTime createdAt;

  Task(this.userID, this.title, this.description, this.date, this.time, this.destination, this.createdAt);

  Future<void> addToFirestore() async {
    final firestore = FirebaseFirestore.instance;

    try {
      if( title == '') {
        throw Exception('Field cannot be empty.');
      } else {
        await firestore.collection("users")
            .doc(userID)
            .collection("tasks")
            .add(
              {
                'title': title,
                'description': description,
                'date': date.millisecondsSinceEpoch,
                'time': time.toString(),
                'destination': destination.toString(),
                'createdAt': createdAt.toUtc(),
              }
            );
      }
    } catch (e) {
      throw Exception('Task cannot be added to firebase.');
    }

  }
}
