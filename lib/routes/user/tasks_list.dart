import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../util/constants.dart';

class TasksList extends StatefulWidget {
  const TasksList({super.key});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  String? userID = '';
  List<Widget> tasksList = [];

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user?.uid;

    handleTasksData();
    if( tasksList == []) {
      throw Exception("The list is still empty!");
    }
  }

  void handleTasksData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .collection("tasks")
        .get();

    if (snapshot.docs.isNotEmpty) {
      tasksList = snapshot.docs.map((doc) {
        String title = doc['title'];
        String description = doc['description'];
        DateTime date = DateTime.fromMillisecondsSinceEpoch(doc['date']);
        TimeOfDay? time = (doc['time'] != '') ?
          TimeOfDay(hour: int.parse(doc['time'].split(':')[0]),
                    minute: int.parse(doc['time'].split(':')[1]),
                   ) : null;
        LatLng? destination = (doc['destination'] != '') ?
          LatLng(double.parse(doc['destination'].split(',')[0]),
                 double.parse(doc['destination'].split(',')[1]),
                ) : null;

        if( title == '') {
          throw Exception("The tasks cannot pe accessed!");
        }
        return Dismissible(
          key: Key(doc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            child: const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          onDismissed: (direction) async {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(userID)
                .collection("tasks")
                .doc(doc.id)
                .delete();
            setState(() {});
          },
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  width: 20,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(title),
                          subtitle: Text(description),
                          trailing: Transform.scale(
                            scale: 1.5,
                            child: Checkbox(
                              activeColor: primaryColor,
                              shape: const CircleBorder(),
                              value: false, // Update with task completion status
                              onChanged: (value) => print(value),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -12),
                          child: Container(
                            child: Column(
                              children: [
                                Divider(
                                  thickness: 1.5,
                                  color: Colors.grey.shade200,
                                ),
                                Row(
                                  children: [
                                    Text(DateFormat('EEEE, d MMMM').format(date)), // Update with task date
                                    SizedBox(height: 16,),
                                    Text(time != null ? "${time!.hour}:${time!.minute}" : ""),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasksList.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            tasksList[index],
            SizedBox(height: 16), // Adjust the height as needed
          ],
        );
      },
    );
  }
}