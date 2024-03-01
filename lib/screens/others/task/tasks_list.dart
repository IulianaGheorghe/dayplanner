import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayplanner/screens/others/task/task_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../util/constants.dart';

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
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .collection("tasks")
        .where('date', isGreaterThanOrEqualTo: startOfToday.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: endOfToday.millisecondsSinceEpoch)
        .get();

    if (snapshot.docs.isNotEmpty) {
      tasksList = snapshot.docs.map((doc) {
        String title = doc['title'];
        String description = doc['description'];
        DateTime date = DateTime.fromMillisecondsSinceEpoch(doc['date']);
        TimeOfDay? startTime = (doc['startTime'] != '') ?
          TimeOfDay(hour: int.parse(doc['startTime'].split(':')[0]),
                    minute: int.parse(doc['startTime'].split(':')[1]),
          ) : null;
        TimeOfDay? deadline = (doc['deadline'] != '') ?
          TimeOfDay(hour: int.parse(doc['deadline'].split(':')[0]),
                    minute: int.parse(doc['deadline'].split(':')[1]),
          ) : null;
        String priority = doc['priority'];
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
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetails(
                    title: title,
                    description: description,
                    date: date,
                    startTime: startTime,
                    deadline: deadline,
                    priority: priority,
                    destination: destination,
                  ),
                ),
              );
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
                    decoration: BoxDecoration(
                      color: getColorForPriority(priority),
                      borderRadius: const BorderRadius.only(
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
                            title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                            subtitle: Text(DateFormat('EEEE, d MMMM').format(date)),
                            trailing: Transform.scale(
                              scale: 1.5,
                              child: Checkbox(
                                activeColor: primaryColor,
                                shape: const CircleBorder(),
                                value: false,
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
                                      startTime != null ?
                                        Text("Start time: ${startTime.hour}:${startTime.minute}")
                                        : const Text(""),
                                      const SizedBox(width: 32),
                                      deadline != null ?
                                        Text( "Deadline: ${deadline.hour}:${deadline.minute}")
                                        : const Text(""),
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
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Color getColorForPriority(String option) {
    switch (option) {
      case 'Low':
        return Colors.blue;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}