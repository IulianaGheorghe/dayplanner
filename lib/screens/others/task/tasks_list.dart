import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dayplanner/screens/others/task/task_details.dart';
import 'package:dayplanner/services/task_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../util/components.dart';
import '../../../util/constants.dart';

class TasksList extends StatefulWidget {
  const TasksList({super.key});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  String? userID = '';
  List<Map<String, dynamic>> tasksData = [];

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    userID = user?.uid;

    handleTasksData();
  }

  void handleTasksData() async {
    tasksData = await getTasksDetails(userID!);
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(todayDate);

    return ListView.builder(
      itemCount: tasksData.length,
      itemBuilder: (context, index) {
        final task = tasksData[index];
        bool? isChecked = task['status'] == 'Done';

        return Column(
            children: [
              Dismissible(
                key: Key(task['id']),
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
                      .doc(formattedDate)
                      .collection("day tasks")
                      .doc(task['id'])
                      .delete();
                  setState(() {});
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                          TaskDetails(
                              title: task['title'],
                              description: task['description'],
                              date: task['date'],
                              startTime: task['startTime'],
                              deadline: task['deadline'],
                              priority: task['priority'],
                              destination: task['destination'],
                              status: task['status']
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
                            color: getColorForPriority(task['priority']),
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
                                  title: Text(task['title'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                  subtitle: Text(DateFormat('EEEE, d MMMM').format(task['date'])),
                                  trailing: Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                      checkColor: Colors.greenAccent,
                                      activeColor: primaryColor,
                                      shape: const CircleBorder(),
                                      value: isChecked,
                                      onChanged: (value) =>
                                          setState(() {
                                            isChecked = value;
                                            task['status'] = (isChecked == true)
                                                ? 'Done'
                                                : 'To do';
                                            updateStatus(userID!, task['id'], formattedDate, task['status']);
                                          }),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -12),
                                  child: Column(
                                    children: [
                                      Divider(
                                        thickness: 1.5,
                                        color: Colors.grey.shade200,
                                      ),
                                      Row(
                                        children: [
                                          task['startTime'] != null ?
                                            Text("Start time: ${task['startTime'].hour}:${task['startTime'].minute}")
                                            : const Text(""),
                                          const SizedBox(width: 32),
                                          task['deadline'] != null ?
                                            Text("Deadline: ${task['deadline'].hour}:${task['deadline'].minute}")
                                            : const Text(""),
                                        ],
                                      )
                                    ],
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
              ),
              const SizedBox(height: 16),
            ]
        );
      },
    );
  }
}