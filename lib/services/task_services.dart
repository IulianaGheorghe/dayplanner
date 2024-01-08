import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String userID;
  String title;
  String description;
  DateTime createdAt;

  Task(this.userID, this.title, this.description, this.createdAt);

  Future<void> addToFirestore() async {
    final firestore = FirebaseFirestore.instance;
    try {
      if( title == '' || description == '') {
        throw Exception('Field cannot be empty.');
      } else {
        await firestore.collection("trainers")
            .doc(userID)
            .collection("news")
            .add({'title': title,
          'description': description,
          'createdAt': createdAt.toUtc(),});
      }
    } catch (e) {
      throw Exception('Task cannot be added to firebase.');
    }
  }
}
